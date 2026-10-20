#import <Foundation/Foundation.h>
#import <TargetConditionals.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_UI_ACTOR
@interface WKTWScreenTimeRuntime : NSObject
+ (BOOL)installWithError:(NSError * _Nullable * _Nullable)error NS_SWIFT_NAME(install());
@end

#if TARGET_OS_IOS && TARGET_OS_SIMULATOR

@interface WKTWLaunchctlResult : NSObject
@property (nonatomic, readonly) int exitStatus;
@property (nonatomic, readonly, copy) NSData *output;
@end

@interface WKTWLaunchctl : NSObject
+ (nullable WKTWLaunchctlResult *)runWithArguments:(NSArray<NSString *> *)arguments
                                          error:(NSError * _Nullable * _Nullable)error
    NS_SWIFT_NAME(run(arguments:));
@end

#endif

NS_ASSUME_NONNULL_END
