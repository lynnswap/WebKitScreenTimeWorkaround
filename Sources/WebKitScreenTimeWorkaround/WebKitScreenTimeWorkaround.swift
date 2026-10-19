internal import WebKitScreenTimeWorkaroundRuntime

/// Disables Screen Time integration in web views created after installation.
@MainActor
public enum ScreenTimeWorkaround {
    /// Installs the workaround for the lifetime of the current process.
    ///
    /// Call this in the process that creates the web views, before creating the
    /// first web view. Repeated calls have no additional effect. Configurations
    /// supplied by the caller retain their original preferences.
    ///
    /// - Throws: An error if this WebKit runtime does not expose the required
    ///   private APIs or cannot disable its Screen Time feature.
    public static func install() throws {
        try WSTScreenTimeRuntime.install()
    }
}
