to: src/views/admin/login.rs
skip_exists: true
message: "Admin login view module was added successfully."
injections:
- into: src/views/admin/mod.rs
  append: true
  content: "pub mod login;"
---
use loco_rs::prelude::*;

/// Render the admin login form.
///
/// # Errors
///
/// Returns an error when the template cannot be rendered.
pub fn page(
    v: &impl ViewRenderer,
    error: Option<&str>,
    username: Option<&str>,
) -> Result<Response> {
    format::render().view(
        v,
        "admin/login.html",
        data!({
            "error": error,
            "username": username.unwrap_or_default()
        }),
    )
}
