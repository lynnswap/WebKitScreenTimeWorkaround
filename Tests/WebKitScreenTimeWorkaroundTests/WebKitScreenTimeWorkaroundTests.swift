import Foundation
import ObjectiveC
import Testing
import WebKit
import WebKitScreenTimeWorkaround

@MainActor
@Suite(.serialized)
struct WebKitScreenTimeWorkaroundTests {
    @Test
    func newWebViewsPreserveSuppliedConfiguration() throws {
        let feature = try ScreenTimeFeature()
        let configuration = WKWebViewConfiguration()
        configuration.preferences.minimumFontSize = 19
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = true
        configuration.applicationNameForUserAgent = "WorkaroundTests"
        configuration.websiteDataStore = .nonPersistent()
        let preferences = configuration.preferences
        feature.setEnabled(true, in: preferences)

        for _ in 0..<2 {
            try ScreenTimeWorkaround.install()
            let webView = WKWebView(frame: .zero, configuration: configuration)
            let actual = webView.configuration

            #expect(!feature.isEnabled(in: actual.preferences))
            #expect(actual.preferences.minimumFontSize == 19)
            #expect(actual.preferences.javaScriptCanOpenWindowsAutomatically)
            #expect(actual.applicationNameForUserAgent == "WorkaroundTests")
            #expect(actual.websiteDataStore === configuration.websiteDataStore)
            #expect(actual.userContentController === configuration.userContentController)
            #expect(configuration.preferences === preferences)
            #expect(feature.isEnabled(in: preferences))
        }
    }

    @Test
    func decodedWebViewsDisableScreenTime() throws {
        try ScreenTimeWorkaround.install()
        let feature = try ScreenTimeFeature()
        let configuration = WKWebViewConfiguration()
        configuration.preferences.minimumFontSize = 19
        feature.setEnabled(true, in: configuration.preferences)

        let webView = WKWebView()
        webView.customUserAgent = "WorkaroundTests"
        let delegate = ConfigurationArchiveDelegate(configuration: configuration)
        let archiver = NSKeyedArchiver(requiringSecureCoding: false)
        archiver.delegate = delegate
        archiver.encode(webView, forKey: NSKeyedArchiveRootObjectKey)
        archiver.finishEncoding()
        try #require(delegate.didReplaceConfiguration)

        let unarchiver = try NSKeyedUnarchiver(forReadingFrom: archiver.encodedData)
        unarchiver.requiresSecureCoding = false
        defer { unarchiver.finishDecoding() }
        let decoded = try #require(
            unarchiver.decodeObject(forKey: NSKeyedArchiveRootObjectKey) as? WKWebView
        )

        #expect(!feature.isEnabled(in: decoded.configuration.preferences))
        #expect(decoded.configuration.preferences.minimumFontSize == 19)
        #expect(decoded.customUserAgent == "WorkaroundTests")
        #expect(feature.isEnabled(in: configuration.preferences))
    }
}

@MainActor
private struct ScreenTimeFeature {
    private typealias Getter = @convention(c) (AnyObject, Selector, AnyObject) -> ObjCBool
    private typealias Setter = @convention(c) (AnyObject, Selector, ObjCBool, AnyObject) -> Void
    private let feature: NSObject
    private let getter: Getter
    private let setter: Setter
    private let getterSelector = NSSelectorFromString("_isEnabledForFeature:")
    private let setterSelector = NSSelectorFromString("_setEnabled:forFeature:")

    init() throws {
        let featuresSelector = NSSelectorFromString("_features")
        let featuresMethod = try #require(class_getClassMethod(WKPreferences.self, featuresSelector))
        typealias Features = @convention(c) (AnyObject, Selector) -> Unmanaged<NSArray>
        let features = unsafeBitCast(method_getImplementation(featuresMethod), to: Features.self)(
            WKPreferences.self, featuresSelector
        ).takeUnretainedValue()
        feature = try #require((features as? [NSObject])?.first {
            $0.value(forKey: "key") as? String == "ScreenTimeEnabled"
        })
        let getterMethod = try #require(class_getInstanceMethod(WKPreferences.self, getterSelector))
        let setterMethod = try #require(class_getInstanceMethod(WKPreferences.self, setterSelector))
        getter = unsafeBitCast(method_getImplementation(getterMethod), to: Getter.self)
        setter = unsafeBitCast(method_getImplementation(setterMethod), to: Setter.self)
    }

    func isEnabled(in preferences: WKPreferences) -> Bool {
        getter(preferences, getterSelector, feature).boolValue
    }

    func setEnabled(_ enabled: Bool, in preferences: WKPreferences) {
        setter(preferences, setterSelector, ObjCBool(enabled), feature)
    }
}

private final class ConfigurationArchiveDelegate: NSObject, NSKeyedArchiverDelegate {
    let configuration: WKWebViewConfiguration
    var didReplaceConfiguration = false

    init(configuration: WKWebViewConfiguration) {
        self.configuration = configuration
    }

    func archiver(_ archiver: NSKeyedArchiver, willEncode object: Any) -> Any? {
        guard object is WKWebViewConfiguration else { return object }
        didReplaceConfiguration = true
        // Encode an enabled configuration so decoding must apply the workaround again.
        return configuration
    }
}
