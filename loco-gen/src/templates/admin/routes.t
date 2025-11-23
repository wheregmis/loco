to: src/controllers/admin/mod.rs
message: "Admin routes module was added successfully."
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

