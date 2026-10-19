# WebKitScreenTimeWorkaround

A Swift package for tests that disables Screen Time integration in newly created `WKWebView` instances. It works around the Screen Time-related stalls documented in [WKWebViewScreenTimeRepro](https://github.com/lynnswap/WKWebViewScreenTimeRepro).

## Requirements

Swift 6.3 or later is required.

| Platform | Package deployment target | Workaround installation |
| --- | --- | --- |
| iOS / iPadOS | 17.0 or later | 26.1 or later |
| macOS | 14.0 or later | 26.1 or later |

The package can be linked on the deployment targets above. The 26.1 installation minimum matches the `STScreenTimeConfigurationObserver` initialization path added between the public WebKit sources for 26.0 and [iOS 26.1](https://github.com/WebKit/WebKit/blob/8914df4ab564e7a9d033eb3666ada075d8878eee/Source/WebKit/UIProcess/API/Cocoa/WKWebView.mm#L428-L435) and [macOS 26.1](https://github.com/WebKit/WebKit/blob/6214d577e8b731b897ec7155a4be62efe1ffd854/Source/WebKit/UIProcess/API/Cocoa/WKWebView.mm#L428-L435). This path creates the observer and reads `configuration.enforcesChildRestrictions`. Guard installation with the availability check below; it also checks for the required private APIs at runtime.

The reproduction project records the delay on iOS 27.0. macOS execution has only been verified on 26.6.2, where tests verify configuration preservation and archived web view decoding; a Screen Time stall and the need for this workaround have not been demonstrated. The source identifies when this observer path was introduced; the earliest OS version with a measurable stall has not been confirmed.

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

On earlier OS versions, this example creates web views without installing the workaround.

Install it in the same process that creates the web views. For tests that launch an app, call it during app startup.

Repeated calls are safe. Once installed, the workaround remains active until the process exits and affects all subsequently initialized `WKWebView` instances. Existing instances are unchanged. Installation throws if the required runtime APIs are unavailable.

The implementation swizzles `WKWebView._initializeWithConfiguration:` and sets the private `ScreenTimeEnabled` preference to `false` before WebKit initializes each web view.

## Documentation

[DocC documentation](https://lynnswap.github.io/WebKitScreenTimeWorkaround/documentation/webkitscreentimeworkaround/)

## Tests

Run the existing configuration-preservation and archive-decoding tests on an iOS simulator:

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
