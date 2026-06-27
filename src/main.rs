//! Binary entry point for `rw-vn100` — delegates to the library crate.
//!
//! All logic lives in the `rw-vn100` library (`lib.rs` and its modules);
//! this binary only forwards to `run`.

/// Forward to the library's `run`, surfacing its error to the process exit.
fn main() -> Result<(), Box<dyn std::error::Error>> {
    rw_vn100::run()
}
