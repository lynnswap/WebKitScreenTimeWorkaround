# ``WebKitScreenTimeWorkaround``

Disable Screen Time integration in new web views to work around stalls during tests.

## Overview

Swift 6.3 or later is required.

| Platform | Package deployment target | Workaround installation |
| --- | --- | --- |
| iOS / iPadOS | 17.0 or later | 26.1 or later |
| macOS | 12.0 or later | 26.1 or later |

The package can be linked on the deployment targets above. The 26.1 installation
minimum matches the `STScreenTimeConfigurationObserver` initialization path added
between the public WebKit sources for 26.0 and [iOS 26.1](https://github.com/WebKit/WebKit/blob/8914df4ab564e7a9d033eb3666ada075d8878eee/Source/WebKit/UIProcess/API/Cocoa/WKWebView.mm#L428-L435) and [macOS 26.1](https://github.com/WebKit/WebKit/blob/6214d577e8b731b897ec7155a4be62efe1ffd854/Source/WebKit/UIProcess/API/Cocoa/WKWebView.mm#L428-L435).
This path creates the observer and reads `configuration.enforcesChildRestrictions`.
Installation also checks for the required private APIs at runtime.

Call ``ScreenTimeWorkaround/install()`` on the main actor before creating the first
`WKWebView` in the process:

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

On earlier OS versions, this example creates web views without installing the
workaround. For tests that launch an app, install the workaround during app startup
in the app process.

## Verification scope

The reproduction project records a Screen Time delay on iOS 27.0. macOS execution
has only been verified on 26.6.2, where the existing tests verify configuration
preservation and archived web view decoding.
A macOS Screen Time stall and the need for this workaround have not been
demonstrated. The source identifies when this observer path was introduced; the
earliest OS version with a measurable stall has not been confirmed.

## Topics

### Installing the workaround

- ``ScreenTimeWorkaround``
- ``ScreenTimeWorkaround/install()``
