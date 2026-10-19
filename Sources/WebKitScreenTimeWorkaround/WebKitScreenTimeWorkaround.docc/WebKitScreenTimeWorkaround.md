# ``WebKitScreenTimeWorkaround``

Disable Screen Time integration in new web views to work around stalls during tests.

## Overview

Swift 6.3 or later is required.

| Platform | Package deployment target | Workaround installation |
| --- | --- | --- |
| iOS / iPadOS | 17.0 or later | 26.1 or later |
| macOS | 12.0 or later | 26.0 or later |

The macOS installation requirement follows WebKit's Screen Time integration build
condition. The package can be linked on earlier deployment targets; use the
availability check below before installation.

Call ``ScreenTimeWorkaround/install()`` on the main actor before creating the first
`WKWebView` in the process:

```swift
import WebKit
import WebKitScreenTimeWorkaround

@MainActor
func makeWebView() throws -> WKWebView {
    if #available(iOS 26.1, macOS 26.0, *) {
        try ScreenTimeWorkaround.install()
    }
    return WKWebView(frame: .zero)
}
```

On earlier OS versions, this example creates web views without installing the
workaround. For tests that launch an app, install the workaround during app startup
in the app process.

## Verification scope

The reproduction project records a Screen Time delay on iOS 27.0. On macOS 26.6.2,
the existing tests verify configuration preservation and archived web view decoding.
A macOS Screen Time stall and the need for this workaround have not been
demonstrated. The first affected OS version has not been confirmed on either
platform.

## Topics

### Installing the workaround

- ``ScreenTimeWorkaround``
- ``ScreenTimeWorkaround/install()``
