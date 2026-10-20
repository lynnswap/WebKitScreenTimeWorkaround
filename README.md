# WebKitTestWorkarounds

A Swift package of opt-in workarounds for `WKWebView` tests. The Screen Time workaround uses private WebKit APIs to disable Screen Time integration and avoid the stalls reproduced in [WKWebViewScreenTimeRepro](https://github.com/lynnswap/WKWebViewScreenTimeRepro).

## Requirements

- Swift 6.3 or later
- Deployment target: iOS/iPadOS 17 or macOS 14 or later
- `ScreenTimeWorkaround.install()`: iOS/iPadOS 26.1 or macOS 26.1 or later

## Installation

Add the package in Xcode using this URL:

```text
https://github.com/lynnswap/WebKitTestWorkarounds
```

Choose the `main` branch and add the `WebKitTestWorkarounds` product to the target that creates your web views.

For a Swift package, add this dependency:

```swift
.package(
    url: "https://github.com/lynnswap/WebKitTestWorkarounds.git",
    branch: "main"
)
```

Then add `"WebKitTestWorkarounds"` to your target's dependencies.

## Screen Time workaround

Call `ScreenTimeWorkaround.install()` on the main actor before creating the first `WKWebView`:

```swift
import WebKit
import WebKitTestWorkarounds

@MainActor
func makeWebView() throws -> WKWebView {
    if #available(iOS 26.1, macOS 26.1, *) {
        try ScreenTimeWorkaround.install()
    }
    return WKWebView(frame: .zero)
}
```

For tests that launch an app, install the workaround during app startup, in the app process. On earlier OS versions, the example creates web views without the workaround.

Once installed, it affects all new `WKWebView` instances until the process exits. Existing web views are unchanged. Installation throws if the required private APIs are unavailable, and repeated calls reuse the first installation result.

## Migrating from 0.3.0

When updating from `WebKitScreenTimeWorkaround` 0.3.0, use the package URL and `main` branch above, change the product dependency to `WebKitTestWorkarounds`, and replace `import WebKitScreenTimeWorkaround` with `import WebKitTestWorkarounds`. Calls to `ScreenTimeWorkaround.install()` stay the same.

## Documentation

[API documentation](https://lynnswap.github.io/WebKitTestWorkarounds/documentation/webkittestworkarounds/)

## Tests

Run the configuration preservation and archive decoding tests on an iOS simulator:

```sh
xcodebuild test \
    -scheme WebKitTestWorkarounds \
    -destination 'platform=iOS Simulator,name=iPhone 17,OS=27.0'
```

Run the same tests on a Mac:

```sh
xcodebuild test \
    -scheme WebKitTestWorkarounds \
    -destination 'platform=macOS,arch=arm64'
```

## License

MIT. Copyright (c) 2026 Kazuki Nakashima. See [LICENSE](LICENSE).
