to: src/controllers/admin/dashboard.rs
skip_exists: true
message: "Admin dashboard controller was added successfully."
injections:
- into: src/controllers/admin/mod.rs
  append: true
  content: "pub mod dashboard;"
---
#![allow(clippy::missing_errors_doc)]
#![allow(clippy::unnecessary_struct_initialization)]
#![allow(clippy::unused_async)]
use loco_rs::prelude::*;

use crate::views;

use loco_rs::controller::extractor::auth;

#[debug_handler]
pub async fn index(
    _auth: auth::JWT,
    ViewEngine(v): ViewEngine<TeraView>,
    State(_ctx): State<AppContext>,
) -> Result<Response> {
    views::admin::dashboard::index(&v)
}

pub fn routes() -> Routes {
    Routes::new()
        .prefix("{{prefix}}/")
        .add("/", get(index))
}

