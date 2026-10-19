internal import WebKitScreenTimeWorkaroundRuntime

/// Disables Screen Time integration in web views initialized after installation.
///
/// Use ``install()`` to apply the workaround before a test creates its web views.
@MainActor
public enum ScreenTimeWorkaround {
    /// Installs the workaround for subsequent web view initializations in the current process.
    ///
    /// Call this method on the main actor before creating the first `WKWebView`.
    /// Install it in the process that creates the web views. For tests that launch
    /// an app, call it during app startup.
    ///
    /// Successful installation affects all subsequently initialized web views,
    /// including views decoded from archives, until the process exits. Existing
    /// web views are unchanged. Configurations and preferences supplied by callers
    /// retain their original settings.
    ///
    /// Repeated calls reuse the result of the first attempt. If installation
    /// fails, no hook is installed, and subsequent calls throw the same error.
    ///
    /// - Throws: An error if this WebKit runtime does not expose the required
    ///   private APIs, lacks the `ScreenTimeEnabled` feature, or cannot disable it.
    @available(iOS 26.1, macOS 12.0, *)
    public static func install() throws {
        try WSTScreenTimeRuntime.install()
    }
}
