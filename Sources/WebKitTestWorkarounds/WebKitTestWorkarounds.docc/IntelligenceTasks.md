# Stopping and restoring Intelligence Tasks

Temporarily stop `intelligencetasksd` during tests and restore its launchd registration afterward.

## Overview

`IntelligenceTasksWorkaround` is available only on iOS/iPadOS Simulator through the
`WebKitTestWorkarounds` product. Its synchronous `stop()` and `restore()` methods run
on the main actor.

The change affects the entire current Simulator. The target is
`user/foreground/com.apple.intelligencetasksd` in the calling process's bootstrap
environment. The API does not select another Simulator by UDID.

## Pair stopping with restoration

Always attempt `restore()` after the operation, even if `stop()` or the operation
throws. This Swift Testing example installs cleanup before stopping the service,
and records a restoration error as a test failure:

```swift
import Testing
import WebKit
import WebKitTestWorkarounds

#if os(iOS) && targetEnvironment(simulator)
@Test
@MainActor
func newWebView() throws {
    defer {
        do {
            try IntelligenceTasksWorkaround.restore()
        } catch {
            Issue.record(error)
        }
    }
    try IntelligenceTasksWorkaround.stop()

    let webView = WKWebView(frame: .zero)
    #expect(!webView.isLoading)
}
#endif
```

If your test framework provides setup and teardown hooks, put the pair there and
ensure teardown also runs when setup fails. Report restoration failures alongside
the test's own failures.

The calling process keeps the saved registration information. Exiting or crashing
does not restore the service automatically. Coordinate the pair of calls with
other tests and processes that share the same environment; the API does not track
ownership across callers.

## Registration behavior

`stop()` saves the service's original launchd plist path before unregistering it.
If the service is absent, it returns without changing the registration. Repeated
calls keep the saved path. If unregistering fails, the path remains available for
another `stop()` attempt or for restoration.

`restore()` registers the service from the saved path when it is absent. If it is
already registered, restoration succeeds without registering it again. A
successful restoration clears the saved path; a failed restoration keeps it so
you can retry. With no saved path, `restore()` does nothing.

The workaround leaves launchd's enabled and disabled overrides unchanged. It
controls only `intelligencetasksd`; `AppIntentsLiveEntityService` is outside its
scope.
