// SPDX-License-Identifier: GPL-3.0-only

use prayer_times_applet::app::YourApp;

/// The `cosmic::app::run()` function is the starting point of your application.
/// It takes two arguments:
/// - `settings` is a structure that contains everything relevant with your app's configuration, such as antialiasing, themes, icons, etc...
/// - `()` is the flags that your app needs to use before it starts.
///  If your app does not need any flags, you can pass in `()`.
fn main() -> cosmic::iced::Result {
    env_logger::init();
    cosmic::applet::run::<YourApp>(true, ())
}
