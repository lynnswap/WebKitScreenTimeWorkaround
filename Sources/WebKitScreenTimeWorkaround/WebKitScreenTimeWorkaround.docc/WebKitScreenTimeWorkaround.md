# ``WebKitScreenTimeWorkaround``

Disable Screen Time integration in new web views to work around stalls during tests.

## Overview

The package requires iOS / iPadOS 26.1 or later and Swift 6.3 or later.

Call ``ScreenTimeWorkaround/install()`` on the main actor before creating the first
`WKWebView` in the process:

```swift
import WebKit
import WebKitScreenTimeWorkaround

@MainActor
func makeWebView() throws -> WKWebView {
    try ScreenTimeWorkaround.install()
    return WKWebView(frame: .zero)
}
```

For tests that launch an app, install the workaround during app startup in the app
process.

## Topics

### Installing the workaround

- ``ScreenTimeWorkaround``
- ``ScreenTimeWorkaround/install()``
