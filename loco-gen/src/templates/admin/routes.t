to: src/controllers/admin/mod.rs
skip_exists: true
message: "Admin routes module was added successfully."
injections:
- into: src/controllers/mod.rs
  append: true
  content: "pub mod admin;"
- into: src/app.rs
  after: "AppRoutes::"
  content: "            .add_route(controllers::admin::routes())"
---
pub mod dashboard;
{% for entity in entities -%}
pub mod {{entity.module_name}};
{% endfor -%}

use loco_rs::prelude::*;

pub fn routes() -> Routes {
    let mut routes = Routes::new();
    
    routes = routes.add_route(dashboard::routes());
    {% for entity in entities -%}
    routes = routes.add_route({{entity.module_name}}::routes());
    {% endfor -%}
    
    routes
}

