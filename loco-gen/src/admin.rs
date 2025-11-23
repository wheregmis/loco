use std::{fs, path::Path};

use cruet::Inflector;
use regex::Regex;
use rrgen::RRgen;
use serde_json::json;

use crate::{AppInfo, Error, GenerateResults, Result};

#[derive(Debug, Clone)]
pub struct EntityInfo {
    pub name: String,
    pub fields: Vec<FieldInfo>,
    pub primary_key: String,
    pub foreign_keys: Vec<ForeignKeyInfo>,
}

#[derive(Debug, Clone)]
pub struct FieldInfo {
    pub name: String,
    pub rust_type: String,
    pub is_nullable: bool,
    pub is_primary: bool,
    pub is_foreign_key: bool,
    pub related_entity: Option<String>,
    pub related_module: Option<String>,
}

#[derive(Debug, Clone)]
pub struct ForeignKeyInfo {
    pub field_name: String,
    pub related_module: String,
}

/// Discover all entities in the project
pub fn discover_entities(exclude: &[String]) -> Result<Vec<EntityInfo>> {
    let entities_dir = Path::new("src/models/_entities");

    if !entities_dir.exists() {
        return Err(Error::Message(
            "src/models/_entities directory not found. Run 'cargo loco db entities' first."
                .to_string(),
        ));
    }

    let mut entities = Vec::new();
    let entries = fs::read_dir(entities_dir)
        .map_err(|e| Error::Message(format!("Failed to read entities directory: {}", e)))?;

    let denylist = ["mod", "prelude"];

    for entry in entries {
        let entry =
            entry.map_err(|e| Error::Message(format!("Failed to read directory entry: {}", e)))?;

        let path = entry.path();
        if path.is_file() && path.extension().and_then(|s| s.to_str()) == Some("rs") {
            let file_name = path
                .file_stem()
                .and_then(|s| s.to_str())
                .ok_or_else(|| Error::Message("Invalid file name".to_string()))?;

            // Skip mod.rs
            if denylist.contains(&file_name) {
                continue;
            }

            // Check if excluded
            let file_name_snake: String = heck::ToSnakeCase::to_snake_case(file_name);
            if exclude
                .iter()
                .any(|e| e == file_name || e == &file_name_snake)
            {
                continue;
            }

            match parse_entity_file(&path, file_name, entities_dir) {
                Ok(entity) => entities.push(entity),
                Err(e) => {
                    tracing::warn!(file = ?path, error = %e, "Failed to parse entity file, skipping");
                }
            }
        }
    }

    Ok(entities)
}

/// Parse an entity file to extract model information
fn parse_entity_file(path: &Path, entity_name: &str, entities_dir: &Path) -> Result<EntityInfo> {
    let content = fs::read_to_string(path).map_err(|e| {
        Error::Message(format!(
            "Failed to read entity file {}: {}",
            path.display(),
            e
        ))
    })?;

    let mut fields = Vec::new();
    let mut primary_key = "id".to_string();
    let mut foreign_keys = Vec::new();

    // Regex patterns for parsing
    let field_re = Regex::new(r#"pub\s+(\w+):\s*([^,]+)"#).unwrap();
    let primary_key_re = Regex::new(r#"#\[sea_orm\(primary_key\)\]"#).unwrap();
    let ignore_fields = ["created_at", "updated_at", "create_at", "update_at"];

    let lines: Vec<&str> = content.lines().collect();
    let mut i = 0;
    while i < lines.len() {
        let line = lines[i].trim();

        // Check for primary key annotation
        if primary_key_re.is_match(line) && i + 1 < lines.len() {
            if let Some(caps) = field_re.captures(lines[i + 1]) {
                primary_key = caps[1].to_string();
            }
        }

        // Parse field
        if let Some(caps) = field_re.captures(line) {
            let field_name = caps[1].to_string();
            let rust_type = caps[2].trim().to_string();

            // Skip ignored fields
            if ignore_fields.contains(&field_name.as_str()) {
                i += 1;
                continue;
            }

            let is_nullable = rust_type.starts_with("Option<");
            let is_primary = field_name == primary_key;

            // Check if it's a foreign key (ends with _id)
            let is_foreign_key = field_name.ends_with("_id");
            let raw_related_entity = if is_foreign_key {
                let base = field_name.strip_suffix("_id").unwrap_or(&field_name);
                let snake_case: String = heck::ToSnakeCase::to_snake_case(base);
                Some(snake_case)
            } else {
                None
            };

            let related_module = raw_related_entity
                .as_ref()
                .map(|entity| resolve_related_entity_module(entity, entities_dir));

            let related_entity = related_module.clone();

            if is_foreign_key {
                if let Some(module) = &related_module {
                    foreign_keys.push(ForeignKeyInfo {
                        field_name: field_name.clone(),
                        related_module: module.clone(),
                    });
                }
            }

            fields.push(FieldInfo {
                name: field_name,
                rust_type,
                is_nullable,
                is_primary,
                is_foreign_key,
                related_entity,
                related_module,
            });
        }

        i += 1;
    }

    // If no primary key found, default to "id"
    if !fields.iter().any(|f| f.is_primary) {
        primary_key = "id".to_string();
    }

    Ok(EntityInfo {
        name: entity_name.to_string(),
        fields,
        primary_key,
        foreign_keys,
    })
}

fn resolve_related_entity_module(base: &str, entities_dir: &Path) -> String {
    let snake = heck::ToSnakeCase::to_snake_case(base);
    let mut candidates = vec![snake.clone()];
    let plural = snake.to_plural();
    if plural != snake {
        candidates.push(plural);
    }
    let singular = snake.to_singular();
    if singular != snake {
        candidates.push(singular);
    }

    for candidate in candidates {
        let path = entities_dir.join(format!("{candidate}.rs"));
        if path.exists() {
            return candidate;
        }
    }

    snake
}

/// Infer HTML input type from Rust type
pub fn infer_form_input_type(field: &FieldInfo) -> (&'static str, bool) {
    let rust_type = field.rust_type.as_str();

    // Foreign keys get dropdowns
    if field.is_foreign_key {
        return ("select", true);
    }

    // Check for Option<T>
    let inner_type = if rust_type.starts_with("Option<") {
        rust_type
            .strip_prefix("Option<")
            .and_then(|s| s.strip_suffix(">"))
            .unwrap_or(rust_type)
    } else {
        rust_type
    };

    // Special cases by field name
    match field.name.as_str() {
        name if name.contains("email") => ("email", !field.is_nullable),
        name if name.contains("password") => ("password", !field.is_nullable),
        name if name.contains("url") => ("url", !field.is_nullable),
        name if name.contains("phone") => ("tel", !field.is_nullable),
        _ => {
            // Type-based inference
            if inner_type.contains("DateTime") || inner_type.contains("Date") {
                ("datetime-local", !field.is_nullable)
            } else if inner_type == "bool" || inner_type == "Option<bool>" {
                ("checkbox", false)
            } else if inner_type.contains("i32")
                || inner_type.contains("i64")
                || inner_type.contains("i16")
                || inner_type.contains("f32")
                || inner_type.contains("f64")
            {
                ("number", !field.is_nullable)
            } else if inner_type.contains("String") || inner_type.contains("str") {
                if field.name.contains("text")
                    || field.name.contains("content")
                    || field.name.contains("description")
                {
                    ("textarea", !field.is_nullable)
                } else {
                    ("text", !field.is_nullable)
                }
            } else {
                ("text", !field.is_nullable)
            }
        }
    }
}

/// Generate admin panel for all discovered entities
pub fn generate(
    rrgen: &RRgen,
    exclude: &[String],
    prefix: &str,
    appinfo: &AppInfo,
) -> Result<GenerateResults> {
    ensure_admin_module_files()?;
    ensure_top_level_modules()?;
    ensure_admin_routes_registered()?;

    let entities = discover_entities(exclude)?;

    if entities.is_empty() {
        return Err(Error::Message(
            "No entities found. Make sure you have generated entities with 'cargo loco db \
             entities'."
                .to_string(),
        ));
    }

    let mut gen_result = GenerateResults {
        rrgen: vec![],
        local_templates: vec![],
    };

    // Generate dashboard
    let dashboard_vars = json!({
        "entities": entities.iter().map(|e| {
            json!({
                "name": e.name.clone(),
                "display_name": e.name.to_pascal_case(),
                "route": format!("{}/{}", prefix.trim_start_matches('/'), e.name.to_kebab_case())
            })
        }).collect::<Vec<_>>(),
        "prefix": prefix,
        "pkg_name": appinfo.app_name
    });

    let dashboard_result =
        crate::render_template(rrgen, Path::new("admin/dashboard.t"), &dashboard_vars)?;
    gen_result.rrgen.extend(dashboard_result.rrgen);
    gen_result
        .local_templates
        .extend(dashboard_result.local_templates);

    // Generate admin controller for each entity
    for entity in &entities {
        let entity_result = generate_entity_admin(rrgen, entity, prefix, appinfo)?;
        gen_result.rrgen.extend(entity_result.rrgen);
        gen_result
            .local_templates
            .extend(entity_result.local_templates);
    }

    // Generate admin routes module
    let routes_vars = json!({
        "entities": entities.iter().map(|e| {
            json!({
                "name": e.name.clone(),
                "module_name": e.name.to_snake_case(),
                "route_prefix": e.name.to_kebab_case()
            })
        }).collect::<Vec<_>>(),
        "prefix": prefix,
        "pkg_name": appinfo.app_name
    });

    let routes_result = crate::render_template(rrgen, Path::new("admin/routes.t"), &routes_vars)?;
    gen_result.rrgen.extend(routes_result.rrgen);
    gen_result
        .local_templates
        .extend(routes_result.local_templates);

    // Generate admin views for each entity
    for entity in &entities {
        let view_result = generate_entity_views(rrgen, entity, prefix)?;
        gen_result.rrgen.extend(view_result.rrgen);
        gen_result
            .local_templates
            .extend(view_result.local_templates);
    }

    // Generate dashboard view
    let dashboard_view_vars = json!({
        "pkg_name": appinfo.app_name,
        "prefix": prefix,
        "entities": entities.iter().map(|e| {
            json!({
                "name": e.name.clone(),
                "display_name": e.name.to_pascal_case(),
                "route": format!("{}/{}", prefix.trim_start_matches('/'), e.name.to_kebab_case())
            })
        }).collect::<Vec<_>>(),
    });
    let dashboard_view_result = crate::render_template(
        rrgen,
        Path::new("admin/view_dashboard.t"),
        &dashboard_view_vars,
    )?;
    gen_result.rrgen.extend(dashboard_view_result.rrgen);
    gen_result
        .local_templates
        .extend(dashboard_view_result.local_templates);

    // Generate admin base HTML template (only once)
    let base_vars = json!({
        "prefix": prefix,
    });
    let base_result = crate::render_template(rrgen, Path::new("admin/html/base.t"), &base_vars)?;
    gen_result.rrgen.extend(base_result.rrgen);
    gen_result
        .local_templates
        .extend(base_result.local_templates);

    // Generate dashboard HTML template
    let dashboard_html_result = crate::render_template(
        rrgen,
        Path::new("admin/html/dashboard.t"),
        &dashboard_view_vars,
    )?;
    gen_result.rrgen.extend(dashboard_html_result.rrgen);
    gen_result
        .local_templates
        .extend(dashboard_html_result.local_templates);

    Ok(gen_result)
}

fn ensure_admin_module_files() -> Result<()> {
    create_mod_file_if_missing(
        Path::new("src/controllers/admin/mod.rs"),
        "//! Auto-generated admin controllers module.\n",
    )?;
    create_mod_file_if_missing(
        Path::new("src/views/admin/mod.rs"),
        "//! Auto-generated admin views module.\n",
    )?;
    Ok(())
}

fn create_mod_file_if_missing(path: &Path, header: &str) -> Result<()> {
    if path.exists() {
        return Ok(());
    }

    if let Some(parent) = path.parent() {
        fs::create_dir_all(parent)?;
    }

    fs::write(path, header)?;
    Ok(())
}

fn ensure_top_level_modules() -> Result<()> {
    ensure_module_export(Path::new("src/controllers/mod.rs"), "pub mod admin;")?;
    ensure_module_export(Path::new("src/views/mod.rs"), "pub mod admin;")?;
    Ok(())
}

fn ensure_module_export(path: &Path, module_line: &str) -> Result<()> {
    if !path.exists() {
        return Ok(());
    }

    let mut content = fs::read_to_string(path)?;
    if content.contains(module_line) {
        return Ok(());
    }

    if !content.ends_with('\n') {
        content.push('\n');
    }
    content.push_str(module_line);
    content.push('\n');
    fs::write(path, content)?;
    Ok(())
}

fn ensure_admin_routes_registered() -> Result<()> {
    let path = Path::new("src/app.rs");
    if !path.exists() {
        return Ok(());
    }

    let content = fs::read_to_string(path)?;
    let registration_line = "            .add_route(controllers::admin::routes())";
    if content.contains(registration_line) {
        return Ok(());
    }

    let anchors = [
        "            .add_route(controllers::auth::routes())",
        "            .add_route(controllers::home::routes())",
        "AppRoutes::with_default_routes() // controller routes below",
    ];

    if let Some(pos) = anchors
        .iter()
        .find_map(|anchor| content.find(anchor).map(|idx| idx + anchor.len()))
    {
        let mut new_content = String::with_capacity(content.len() + registration_line.len() + 1);
        let (head, tail) = content.split_at(pos);
        new_content.push_str(head);
        new_content.push('\n');
        new_content.push_str(registration_line);
        new_content.push_str(tail);
        fs::write(path, new_content)?;
        return Ok(());
    }

    Err(Error::Message(
        "Could not find insertion point for admin routes in src/app.rs".to_string(),
    ))
}

/// Generate admin controller and views for a single entity
fn generate_entity_admin(
    rrgen: &RRgen,
    entity: &EntityInfo,
    prefix: &str,
    appinfo: &AppInfo,
) -> Result<GenerateResults> {
    let mut columns = Vec::new();
    let mut form_fields = Vec::new();

    for field in &entity.fields {
        // Skip primary key and timestamps in forms
        if field.is_primary || field.name == "created_at" || field.name == "updated_at" {
            continue;
        }

        let (input_type, required) = infer_form_input_type(field);
        let mut field_info = json!({
            "name": field.name.clone(),
            "rust_type": field.rust_type.clone(),
            "input_type": input_type,
            "required": required,
            "is_nullable": field.is_nullable,
            "is_foreign_key": field.is_foreign_key,
        });

        if let Some(ref related_module) = field.related_module {
            field_info["related_entity"] = json!(related_module.to_pascal_case());
            field_info["related_module"] = json!(related_module);
        }

        form_fields.push(field_info.clone());
        columns.push(field_info);
    }

    let vars = json!({
        "name": entity.name.clone(),
        "module_name": entity.name.to_snake_case(),
        "display_name": entity.name.to_pascal_case(),
        "route_prefix": entity.name.to_kebab_case(),
        "primary_key": entity.primary_key.clone(),
        "columns": columns,
        "form_fields": form_fields,
        "foreign_keys": entity.foreign_keys.iter().map(|fk| {
            json!({
                "field_name": fk.field_name.clone(),
                "related_entity": fk.related_module.to_pascal_case(),
                "related_module": fk.related_module.clone(),
            })
        }).collect::<Vec<_>>(),
        "prefix": prefix,
        "pkg_name": appinfo.app_name
    });

    crate::render_template(rrgen, Path::new("admin/controller.t"), &vars)
}

/// Generate view modules and HTML templates for a single entity
fn generate_entity_views(
    rrgen: &RRgen,
    entity: &EntityInfo,
    prefix: &str,
) -> Result<GenerateResults> {
    let mut columns = Vec::new();
    let mut form_fields = Vec::new();

    for field in &entity.fields {
        // Skip timestamps in list view but show primary key
        if field.name == "created_at" || field.name == "updated_at" {
            continue;
        }

        let (input_type, required) = infer_form_input_type(field);
        let mut field_info = json!({
            "name": field.name.clone(),
            "rust_type": field.rust_type.clone(),
            "input_type": input_type,
            "required": required,
            "is_nullable": field.is_nullable,
            "is_foreign_key": field.is_foreign_key,
        });

        if let Some(ref related_module) = field.related_module {
            field_info["related_entity"] = json!(related_module.to_pascal_case());
            field_info["related_module"] = json!(related_module);
        }

        columns.push(field_info.clone());

        // Form fields exclude primary key
        if !field.is_primary {
            form_fields.push(field_info);
        }
    }

    let vars = json!({
        "name": entity.name.clone(),
        "module_name": entity.name.to_snake_case(),
        "display_name": entity.name.to_pascal_case(),
        "route_prefix": entity.name.to_kebab_case(),
        "primary_key": entity.primary_key.clone(),
        "columns": columns,
        "form_fields": form_fields,
        "foreign_keys": entity.foreign_keys.iter().map(|fk| {
            json!({
                "field_name": fk.field_name.clone(),
                "related_entity": fk.related_module.to_pascal_case(),
                "related_module": fk.related_module.clone(),
            })
        }).collect::<Vec<_>>(),
        "prefix": prefix,
    });

    // Generate view module
    let mut result = crate::render_template(rrgen, Path::new("admin/view.t"), &vars)?;

    // Generate entity-specific HTML templates (list, create, edit, show)
    let list_result = crate::render_template(rrgen, Path::new("admin/html/list.t"), &vars)?;
    result.rrgen.extend(list_result.rrgen);
    result.local_templates.extend(list_result.local_templates);

    let create_result = crate::render_template(rrgen, Path::new("admin/html/create.t"), &vars)?;
    result.rrgen.extend(create_result.rrgen);
    result.local_templates.extend(create_result.local_templates);

    let edit_result = crate::render_template(rrgen, Path::new("admin/html/edit.t"), &vars)?;
    result.rrgen.extend(edit_result.rrgen);
    result.local_templates.extend(edit_result.local_templates);

    let show_result = crate::render_template(rrgen, Path::new("admin/html/show.t"), &vars)?;
    result.rrgen.extend(show_result.rrgen);
    result.local_templates.extend(show_result.local_templates);

    Ok(result)
}
