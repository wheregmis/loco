{% set file_name = module_name |  snake_case -%}
{% set module_name_pascal = module_name | pascal_case -%}
to: src/views/admin/{{ file_name }}.rs
skip_exists: true
message: "Admin view `{{module_name_pascal}}` was added successfully."
injections:
- into: src/views/admin/mod.rs
  append: true
  content: "pub mod {{ file_name }};"
---
use loco_rs::prelude::*;

use crate::models::_entities::{{name | plural}};

{% for fk in foreign_keys -%}
use crate::models::_entities::{{fk.related_entity | plural}};
{% endfor -%}

/// Render a list view of `{{name | plural}}`.
///
/// # Errors
///
/// When there is an issue with rendering the view.
pub fn list(
    v: &impl ViewRenderer,
    items: &Vec<{{name | plural}}::Model>,
    page: u64,
    total_pages: u64,
    search: &Option<String>,
) -> Result<Response> {
    format::render().view(
        v,
        "admin/{{file_name}}/list.html",
        data!({
            "items": items,
            "page": page,
            "total_pages": total_pages,
            "search": search
        }),
    )
}

/// Render a single `{{name}}` view.
///
/// # Errors
///
/// When there is an issue with rendering the view.
pub fn show(v: &impl ViewRenderer, item: &{{name | plural}}::Model) -> Result<Response> {
    format::render().view(v, "admin/{{file_name}}/show.html", data!({"item": item}))
}

/// Render a `{{name}}` create form.
///
/// # Errors
///
/// When there is an issue with rendering the view.
pub fn create(
    v: &impl ViewRenderer{% for fk in foreign_keys %},
    {{fk.related_module}}_items: &Vec<{{fk.related_entity | plural}}::Model>{% endfor %}
) -> Result<Response> {
    format::render().view(
        v,
        "admin/{{file_name}}/create.html",
        data!({{% for fk in foreign_keys %}
            "{{fk.related_module}}_items": {{fk.related_module}}_items,{% endfor %}
        }),
    )
}

/// Render a `{{name}}` edit form.
///
/// # Errors
///
/// When there is an issue with rendering the view.
pub fn edit(
    v: &impl ViewRenderer,
    item: &{{name | plural}}::Model{% for fk in foreign_keys %},
    {{fk.related_module}}_items: &Vec<{{fk.related_entity | plural}}::Model>{% endfor %}
) -> Result<Response> {
    format::render().view(
        v,
        "admin/{{file_name}}/edit.html",
        data!({
            "item": item{% for fk in foreign_keys %},
            "{{fk.related_module}}_items": {{fk.related_module}}_items{% endfor %}
        }),
    )
}

