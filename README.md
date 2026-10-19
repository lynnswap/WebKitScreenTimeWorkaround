# WebKitScreenTimeWorkaround

A Swift package for tests that disables Screen Time integration in newly created `WKWebView` instances. It works around the Screen Time-related stalls documented in [WKWebViewScreenTimeRepro](https://github.com/lynnswap/WKWebViewScreenTimeRepro).

## Requirements

- iOS / iPadOS 26.1 or later
- Swift 6.3 or later

The minimum OS version follows the introduction of the Screen Time configuration observer involved in this issue. The reproduction project records the delay on iOS 27.0; the first affected OS version has not been confirmed by testing.

## Installation

Add the package in Xcode using this URL:

```text
https://github.com/lynnswap/WebKitScreenTimeWorkaround
```

Choose the `main` branch and add the `WebKitScreenTimeWorkaround` product to the target that creates your web views.

For a Swift package, add this dependency:

```swift
.package(
    url: "https://github.com/lynnswap/WebKitScreenTimeWorkaround.git",
    branch: "main"
)
```

Then add `"WebKitScreenTimeWorkaround"` to your target's dependencies.

## Usage

Call `install()` on the main actor before creating the first `WKWebView`:

```swift
import WebKit
import WebKitScreenTimeWorkaround

@MainActor
func makeWebView() throws -> WKWebView {
    try ScreenTimeWorkaround.install()
    return WKWebView(frame: .zero)
}
```

Install it in the same process that creates the web views. For tests that launch an app, call it during app startup.

Repeated calls are safe. Once installed, the workaround remains active until the process exits and affects all subsequently initialized `WKWebView` instances. Existing instances are unchanged. Installation throws if the required runtime APIs are unavailable.

The implementation swizzles `WKWebView._initializeWithConfiguration:` and sets the private `ScreenTimeEnabled` preference to `false` before WebKit initializes each web view.

## Documentation

[DocC documentation](https://lynnswap.github.io/WebKitScreenTimeWorkaround/documentation/webkitscreentimeworkaround/)

## Tests

Run the tests on an iOS simulator:

```sh
xcodebuild test \
    -scheme WebKitScreenTimeWorkaround \
    -destination 'platform=iOS Simulator,name=iPhone 17,OS=27.0'
```

## License

MIT. Copyright (c) 2026 Kazuki Nakashima. See [LICENSE](LICENSE).
