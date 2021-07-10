#import <React/RCTBridgeModule.h>
#import <React/RCTConvert.h>

typedef NS_ENUM(NSInteger, RNPermission) {
  RNPermissionUnknown = 0,
#if __has_include("RNPermissionHandlerCamera.h")
  RNPermissionCamera = 3,
#endif
#if __has_include("RNPermissionHandlerLocationAlways.h")
  RNPermissionLocationAlways = 6,
#endif
#if __has_include("RNPermissionHandlerLocationWhenInUse.h")
  RNPermissionLocationWhenInUse = 7,
#endif
#if __has_include("RNPermissionHandlerMicrophone.h")
  RNPermissionMicrophone = 9,
#endif
#if __has_include("RNPermissionHandlerAppTrackingTransparency.h")
  RNPermissionAppTrackingTransparency = 16,
#endif
};

@interface RCTConvert (RNPermission)
@end

typedef enum {
  RNPermissionStatusNotAvailable = 0,
  RNPermissionStatusNotDetermined = 1,
  RNPermissionStatusRestricted = 2,
  RNPermissionStatusDenied = 3,
  RNPermissionStatusAuthorized = 4,
} RNPermissionStatus;

@protocol RNPermissionHandler <NSObject>

@required

+ (NSArray<NSString *> * _Nonnull)usageDescriptionKeys;

+ (NSString * _Nonnull)handlerUniqueId;

- (void)checkWithResolver:(void (^ _Nonnull)(RNPermissionStatus status))resolve
                 rejecter:(void (^ _Nonnull)(NSError * _Nonnull error))reject;

- (void)requestWithResolver:(void (^ _Nonnull)(RNPermissionStatus status))resolve
                   rejecter:(void (^ _Nonnull)(NSError * _Nonnull error))reject;

@end

@interface RNPermissions : NSObject <RCTBridgeModule>

+ (bool)isFlaggedAsRequested:(NSString * _Nonnull)handlerId;

+ (void)flagAsRequested:(NSString * _Nonnull)handlerId;

@end
