to: src/controllers/admin/auth.rs
skip_exists: true
message: "Admin auth controller was added successfully."
injections:
- into: src/controllers/admin/mod.rs
  append: true
  content: "pub mod auth;"
---
#![allow(clippy::missing_errors_doc)]
#![allow(clippy::unnecessary_struct_initialization)]
#![allow(clippy::unused_async)]
use axum::{extract::Form, response::{IntoResponse, Redirect}};
use axum_extra::extract::{cookie::{Cookie, SameSite}, CookieJar};
use loco_rs::prelude::*;
use serde::Deserialize;
use serde_json::Map;

use crate::{auth, views};

#[derive(Deserialize)]
pub struct LoginForm {
    pub username: String,
    pub password: String,
}

fn invalid_login(
    v: &impl ViewRenderer,
    username: &str,
) -> Result<Response> {
    views::admin::login::page(
        v,
        Some("Invalid username or password"),
        Some(username),
    )
}

#[debug_handler]
pub async fn show(ViewEngine(v): ViewEngine<TeraView>) -> Result<Response> {
    views::admin::login::page(&v, None, None)
}

#[debug_handler]
pub async fn create_session(
    State(ctx): State<AppContext>,
    ViewEngine(v): ViewEngine<TeraView>,
    jar: CookieJar,
    Form(payload): Form<LoginForm>,
) -> Result<Response> {
    let (expected_user, expected_pass) = ctx.config.admin_credentials();
    if payload.username != expected_user || payload.password != expected_pass {
        return invalid_login(&v, &payload.username);
    }

    let jwt_secret = ctx.config.get_jwt_config()?;
    let token = auth::jwt::JWT::new(&jwt_secret.secret)
        .generate_token(jwt_secret.expiration, format!("admin:{}", payload.username), Map::new())
        .map_err(Error::msg)?;

    let cookie = Cookie::build(ctx.config.admin_cookie_name().to_string(), token)
        .same_site(SameSite::Lax)
        .http_only(true)
        .path("/")
        .finish();

    let response = Redirect::to("{{prefix}}/").into_response();
    Ok((jar.add(cookie), response).into_response())
}

#[debug_handler]
pub async fn logout(State(ctx): State<AppContext>, jar: CookieJar) -> Result<Response> {
    let cookie = Cookie::build(ctx.config.admin_cookie_name().to_string(), "")
        .path("/")
        .http_only(true)
        .finish();

    let response = Redirect::to("{{prefix}}/login").into_response();
    Ok((jar.remove(cookie), response).into_response())
}

pub fn routes() -> Routes {
    Routes::new()
        .prefix("{{prefix}}/")
        .add("login", get(show))
        .add("login", post(create_session))
        .add("logout", post(logout))
}
