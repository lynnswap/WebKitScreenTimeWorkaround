# WebKitScreenTimeWorkaround

A Swift package that disables Screen Time integration in `WKWebView` during tests, using private WebKit APIs. It works around the stalls reproduced in [WKWebViewScreenTimeRepro](https://github.com/lynnswap/WKWebViewScreenTimeRepro).

## Requirements

- Swift 6.3 or later
- Deployment target: iOS/iPadOS 17 or macOS 14 or later
- `install()`: iOS/iPadOS 26.1 or macOS 26.1 or later

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
    if #available(iOS 26.1, macOS 26.1, *) {
        try ScreenTimeWorkaround.install()
    }
    return WKWebView(frame: .zero)
}
```

For tests that launch an app, install the workaround during app startup, in the app process. On earlier OS versions, the example creates web views without the workaround.

Once installed, it affects all new `WKWebView` instances until the process exits. Existing web views are unchanged. Installation throws if the required private APIs are unavailable, and repeated calls reuse the first installation result.

## Documentation

[API documentation](https://lynnswap.github.io/WebKitScreenTimeWorkaround/documentation/webkitscreentimeworkaround/)

## Tests

Run the configuration preservation and archive decoding tests on an iOS simulator:

```sh
xcodebuild test \
    -scheme WebKitScreenTimeWorkaround \
    -destination 'platform=iOS Simulator,name=iPhone 17,OS=27.0'
```

Run the same tests on a Mac:

```sh
xcodebuild test \
    -scheme WebKitScreenTimeWorkaround \
    -destination 'platform=macOS,arch=arm64'
```

## License

MIT. Copyright (c) 2026 Kazuki Nakashima. See [LICENSE](LICENSE).
