# ``WebKitTestWorkarounds``

Opt-in workarounds for `WKWebView` tests.

## Overview

Use ``ScreenTimeWorkaround`` to disable Screen Time integration in new web views
and avoid stalls during tests. Install it explicitly in the process that creates
the web views.

The package requires Swift 6.3 or later and supports deployment to iOS/iPadOS 17
and macOS 14 or later. Installing the Screen Time workaround requires iOS/iPadOS
26.1 or macOS 26.1 or later.

## Topics

### Screen Time

- <doc:ScreenTime>
- ``ScreenTimeWorkaround``
