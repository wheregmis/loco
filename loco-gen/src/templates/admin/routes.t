to: src/controllers/admin/mod.rs
message: "Admin routes module was added successfully."
---
pub mod dashboard;
{% for entity in entities -%}
pub mod {{entity.module_name}};
{% endfor -%}

use loco_rs::prelude::*;

pub fn routes() -> Routes {
    Routes::new()
        .merge(dashboard::routes())
        {% for entity in entities -%}
        .merge({{entity.module_name}}::routes())
        {% endfor -%}
}

