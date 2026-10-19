# ``WebKitScreenTimeWorkaround``

Disable Screen Time integration in new web views to work around stalls during tests.

## Overview

The package requires an iOS / iPadOS deployment target of 17.0 or later and Swift 6.3
or later. Installing the workaround requires iOS / iPadOS 26.1 or later.

Call ``ScreenTimeWorkaround/install()`` on the main actor before creating the first
`WKWebView` in the process:

```swift
import WebKit
import WebKitScreenTimeWorkaround

@MainActor
func makeWebView() throws -> WKWebView {
    if #available(iOS 26.1, *) {
        try ScreenTimeWorkaround.install()
    }
    return WKWebView(frame: .zero)
}
```

On earlier OS versions, this example creates web views without installing the
workaround. For tests that launch an app, install the workaround during app startup
in the app process.

## Topics

### Installing the workaround

- ``ScreenTimeWorkaround``
- ``ScreenTimeWorkaround/install()``
