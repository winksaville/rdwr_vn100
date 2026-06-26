//! Binary entry point for `rdwr_vn100` — delegates to the library crate.
//!
//! All logic lives in the `rdwr_vn100` library (`lib.rs` and its modules);
//! this binary only forwards to `run`.

/// Forward to the library's `run`, surfacing its error to the process exit.
fn main() -> Result<(), Box<dyn std::error::Error>> {
    rdwr_vn100::run()
}
