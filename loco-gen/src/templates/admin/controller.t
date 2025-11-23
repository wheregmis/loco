{% set file_name = module_name |  snake_case -%}
{% set module_name_pascal = module_name | pascal_case -%}
to: src/controllers/admin/{{ file_name }}.rs
skip_exists: true
message: "Admin controller `{{module_name_pascal}}` was added successfully."
injections:
- into: src/controllers/admin/mod.rs
  append: true
  content: "pub mod {{ file_name }};"
---
#![allow(clippy::missing_errors_doc)]
#![allow(clippy::unnecessary_struct_initialization)]
#![allow(clippy::unused_async)]
use axum::extract::Query;
use loco_rs::prelude::*;
use serde::{Deserialize, Serialize};
use sea_orm::{sea_query::Order, PaginatorTrait, QueryOrder, QuerySelect};

use crate::{
    models::_entities::{{module_name}}::{ActiveModel, Column, Entity, Model},
    views,
};
use loco_rs::controller::extractor::auth;

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct Params {
    {% for field in form_fields -%}
    {%- if field.is_nullable or field.is_foreign_key -%}
    pub {{field.name}}: Option<{{field.rust_type | replace(from="Option<", to="") | replace(from=">", to="")}}>,
    {%- else -%}
    pub {{field.name}}: {{field.rust_type}},
    {%- endif %}
    {% endfor -%}
}

impl Params {
    fn update(&self, item: &mut ActiveModel) {
      {% for field in form_fields -%}
      {%- if field.is_foreign_key -%}
      if let Some(val) = self.{{field.name}}.clone() {
          item.{{field.name}} = Set(Some(val));
      } else {
          item.{{field.name}} = Set(None);
      }
      {%- elif "Vec<" in field.rust_type -%}
      item.{{field.name}} = Set(self.{{field.name}}.clone());
      {%- elif field.is_nullable -%}
      item.{{field.name}} = Set(self.{{field.name}}.clone());
      {%- elif "i32" in field.rust_type or "i64" in field.rust_type or "i16" in field.rust_type or "Uuid" in field.rust_type or "f32" in field.rust_type or "f64" in field.rust_type or "Decimal" in field.rust_type or "bool" in field.rust_type or "Date" in field.rust_type or "DateTime" in field.rust_type or "DateTimeWithTimeZone" in field.rust_type -%}
      item.{{field.name}} = Set(self.{{field.name}});
      {%- else -%}
      item.{{field.name}} = Set(self.{{field.name}}.clone());
      {%- endif %}
      {% endfor -%}
    }
}

#[derive(Deserialize)]
pub struct ListQuery {
    page: Option<u64>,
    search: Option<String>,
    sort: Option<String>,
}

async fn load_item(ctx: &AppContext, id: i32) -> Result<Model> {
    let item = Entity::find_by_id(id).one(&ctx.db).await?;
    item.ok_or_else(|| Error::NotFound)
}

#[debug_handler]
pub async fn list(
    _auth: auth::JWT,
    ViewEngine(v): ViewEngine<TeraView>,
    State(ctx): State<AppContext>,
    Query(query): Query<ListQuery>,
) -> Result<Response> {
    // Sorting
    let sort_column = query.sort.as_deref().unwrap_or("id");
    let order = if sort_column.starts_with('-') {
        Order::Desc
    } else {
        Order::Asc
    };
    
    // Pagination
    let page = query.page.unwrap_or(1);
    let per_page = 20;
    let offset = ((page - 1) * per_page) as u64;
    
    let items = Entity::find()
        .order_by(Column::Id, order)
        .limit(per_page)
        .offset(offset)
        .all(&ctx.db)
        .await?;
    
    let total = Entity::find().count(&ctx.db).await?;
    let total_pages = (total as f64 / per_page as f64).ceil() as u64;
    
    views::admin::{{file_name}}::list(&v, &items, page, total_pages, &query.search)
}

#[debug_handler]
pub async fn new(
    _auth: auth::JWT,
    ViewEngine(v): ViewEngine<TeraView>,
    {% if foreign_keys | length > 0 -%}
    State(ctx): State<AppContext>,
    {%- else -%}
    State(_ctx): State<AppContext>,
    {%- endif %}
) -> Result<Response> {
    {% for fk in foreign_keys -%}
    let {{fk.related_module}}_items = crate::models::_entities::{{fk.related_module}}::Entity::find()
        .all(&ctx.db)
        .await?;
    {% endfor -%}
    views::admin::{{file_name}}::create(&v{% for fk in foreign_keys %}, &{{fk.related_module}}_items{% endfor %})
}

#[debug_handler]
pub async fn update(
    _auth: auth::JWT,
    Path(id): Path<i32>,
    State(ctx): State<AppContext>,
    Json(params): Json<Params>,
) -> Result<Response> {
    let item = load_item(&ctx, id).await?;
    let mut item = item.into_active_model();
    params.update(&mut item);
    let _ = item.update(&ctx.db).await?;
    format::render().redirect_with_header_key("HX-Redirect", "{{prefix}}/{{route_prefix}}")
}

#[debug_handler]
pub async fn edit(
    _auth: auth::JWT,
    Path(id): Path<i32>,
    ViewEngine(v): ViewEngine<TeraView>,
    {% if foreign_keys | length > 0 -%}
    State(ctx): State<AppContext>,
    {%- else -%}
    State(_ctx): State<AppContext>,
    {%- endif %}
) -> Result<Response> {
    let item = load_item(&ctx, id).await?;
    {% for fk in foreign_keys -%}
    let {{fk.related_module}}_items = crate::models::_entities::{{fk.related_module}}::Entity::find()
        .all(&ctx.db)
        .await?;
    {% endfor -%}
    views::admin::{{file_name}}::edit(&v, &item{% for fk in foreign_keys %}, &{{fk.related_module}}_items{% endfor %})
}

#[debug_handler]
pub async fn show(
    _auth: auth::JWT,
    Path(id): Path<i32>,
    ViewEngine(v): ViewEngine<TeraView>,
    State(ctx): State<AppContext>,
) -> Result<Response> {
    let item = load_item(&ctx, id).await?;
    views::admin::{{file_name}}::show(&v, &item)
}

#[debug_handler]
pub async fn add(
    _auth: auth::JWT,
    State(ctx): State<AppContext>,
    Json(params): Json<Params>,
) -> Result<Response> {
    let mut item = ActiveModel {
        ..Default::default()
    };
    params.update(&mut item);
    let _ = item.insert(&ctx.db).await?;
    format::render().redirect_with_header_key("HX-Redirect", "{{prefix}}/{{route_prefix}}")
}

#[debug_handler]
pub async fn remove(
    _auth: auth::JWT,
    Path(id): Path<i32>,
    State(ctx): State<AppContext>,
) -> Result<Response> {
    load_item(&ctx, id).await?.delete(&ctx.db).await?;
    format::empty()
}

pub fn routes() -> Routes {
    Routes::new()
        .prefix("{{prefix}}/{{route_prefix}}/")
        .add("/", get(list))
        .add("/", post(add))
        .add("new", get(new))
        .add("{id}", get(show))
        .add("{id}/edit", get(edit))
        .add("{id}", delete(remove))
        .add("{id}", put(update))
        .add("{id}", patch(update))
}

