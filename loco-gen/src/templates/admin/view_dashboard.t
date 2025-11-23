to: src/views/admin/dashboard.rs
skip_exists: true
message: "Admin dashboard view was added successfully."
injections:
- into: src/views/admin/mod.rs
  append: true
  content: "pub mod dashboard;"
---
use loco_rs::prelude::*;

/// Render the admin dashboard.
///
/// # Errors
///
/// When there is an issue with rendering the view.
pub fn index(v: &impl ViewRenderer) -> Result<Response> {
    format::render().view(v, "admin/dashboard.html", data!({}))
}

