#import "WebKitTestWorkaroundsRuntime.h"
#import <WebKit/WebKit.h>
#import <objc/runtime.h>

// These declarations match WebKit's WKPreferencesPrivate.h and _WKFeature.h.
@interface NSObject (WKTWFeature)
@property (nonatomic, readonly, copy) NSString *key;
@end

@interface WKPreferences (WKTWFeatures)
+ (NSArray<NSObject *> *)_features;
- (BOOL)_isEnabledForFeature:(NSObject *)feature;
- (void)_setEnabled:(BOOL)enabled forFeature:(NSObject *)feature;
@end

@interface WKWebViewConfiguration (WKTWConfiguration)
- (id)_visitedLinkStore;
@end

static NSError *InstallationError(NSString *description)
{
    // Preserve the domain for callers inspecting bridged errors.
    return [NSError errorWithDomain:@"WebKitScreenTimeWorkaround" code:1
                          userInfo:@{NSLocalizedDescriptionKey: description}];
}

static NSError *Install(void)
{
    if (![WKPreferences respondsToSelector:@selector(_features)]
        || ![WKPreferences instancesRespondToSelector:@selector(_isEnabledForFeature:)]
        || ![WKPreferences instancesRespondToSelector:@selector(_setEnabled:forFeature:)]) {
        return InstallationError(@"This WebKit runtime does not expose the required feature APIs.");
    }

    NSObject *screenTimeFeature = nil;
    for (NSObject *feature in [WKPreferences _features]) {
        if ([feature respondsToSelector:@selector(key)] && [feature.key isEqualToString:@"ScreenTimeEnabled"]) {
            screenTimeFeature = feature;
            break;
        }
    }
    if (!screenTimeFeature)
        return InstallationError(@"ScreenTimeEnabled is absent from this WebKit runtime.");

    SEL selector = NSSelectorFromString(@"_initializeWithConfiguration:");
    Method method = class_getInstanceMethod(WKWebView.class, selector);
    if (!method)
        return InstallationError(@"This WebKit runtime does not expose the web view initialization method.");
    if (![WKWebViewConfiguration instancesRespondToSelector:@selector(_visitedLinkStore)])
        return InstallationError(@"This WebKit runtime does not expose the configuration's visited link store.");

    WKPreferences *preferences = [[WKPreferences alloc] init];
    [preferences _setEnabled:NO forFeature:screenTimeFeature];
    if ([preferences _isEnabledForFeature:screenTimeFeature])
        return InstallationError(@"This WebKit runtime could not disable ScreenTimeEnabled.");

    typedef void (*Initialize)(WKWebView *, SEL, WKWebViewConfiguration *);
    Initialize original = (Initialize)method_getImplementation(method);
    IMP replacement = imp_implementationWithBlock(^(WKWebView *webView, WKWebViewConfiguration *configuration) {
        // Match WebKit's lazy-reference initialization before copying the input.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        (void)configuration.processPool;
#pragma clang diagnostic pop
        (void)configuration.userContentController;
        (void)configuration.preferences;
        (void)[configuration _visitedLinkStore];
        (void)configuration.defaultWebpagePreferences;
        WKWebViewConfiguration *patchedConfiguration = [configuration copy];
        // A configuration copy shares its preferences; copy those separately.
        patchedConfiguration.preferences = [configuration.preferences copy];
        [patchedConfiguration.preferences _setEnabled:NO forFeature:screenTimeFeature];
        original(webView, selector, patchedConfiguration);
    });
    method_setImplementation(method, replacement);
    return nil;
}

@implementation WKTWScreenTimeRuntime

+ (BOOL)installWithError:(NSError **)error
{
    static dispatch_once_t once;
    static NSError *installationError;
    dispatch_once(&once, ^{
        installationError = Install();
    });
    if (error)
        *error = installationError;
    return installationError == nil;
}

@end
