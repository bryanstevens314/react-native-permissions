#import "RNPermissions.h"
#import <React/RCTLog.h>

#if __has_include("RNPermissionHandlerCamera.h")
#import "RNPermissionHandlerCamera.h"
#endif
#if __has_include("RNPermissionHandlerLocationWhenInUse.h")
#import "RNPermissionHandlerLocationWhenInUse.h"
#endif
#if __has_include("RNPermissionHandlerMicrophone.h")
#import "RNPermissionHandlerMicrophone.h"
#endif
#if __has_include("RNPermissionHandlerAppTrackingTransparency.h")
#import "RNPermissionHandlerAppTrackingTransparency.h"
#endif

static NSString* SETTING_KEY = @"@RNPermissions:Requested";

@implementation RCTConvert(RNPermission)

RCT_ENUM_CONVERTER(RNPermission, (@{
#if __has_include("RNPermissionHandlerCamera.h")
  [RNPermissionHandlerCamera handlerUniqueId]: @(RNPermissionCamera),
#endif
#if __has_include("RNPermissionHandlerLocationWhenInUse.h")
  [RNPermissionHandlerLocationWhenInUse handlerUniqueId]: @(RNPermissionLocationWhenInUse),
#endif
#if __has_include("RNPermissionHandlerMicrophone.h")
  [RNPermissionHandlerMicrophone handlerUniqueId]: @(RNPermissionMicrophone),
#endif
#if __has_include("RNPermissionHandlerAppTrackingTransparency.h")
  [RNPermissionHandlerAppTrackingTransparency handlerUniqueId]: @(RNPermissionAppTrackingTransparency),
#endif
}), RNPermissionUnknown, integerValue);

@end

@interface RNPermissions()

@property (nonatomic, strong) NSMutableDictionary<NSString *, id<RNPermissionHandler>> *_Nonnull handlers;

@end

@implementation RNPermissions

RCT_EXPORT_MODULE();

+ (BOOL)requiresMainQueueSetup {
  return YES;
}

- (dispatch_queue_t)methodQueue {
  return dispatch_get_main_queue();
}

- (NSDictionary *)constantsToExport {
  NSMutableArray<NSString *> *available = [NSMutableArray new];

#if __has_include("RNPermissionHandlerCamera.h")
  [available addObject:[RNPermissionHandlerCamera handlerUniqueId]];
#endif
#if __has_include("RNPermissionHandlerLocationWhenInUse.h")
  [available addObject:[RNPermissionHandlerLocationWhenInUse handlerUniqueId]];
#endif
#if __has_include("RNPermissionHandlerMicrophone.h")
  [available addObject:[RNPermissionHandlerMicrophone handlerUniqueId]];
#endif
#if __has_include("RNPermissionHandlerAppTrackingTransparency.h")
  [available addObject:[RNPermissionHandlerAppTrackingTransparency handlerUniqueId]];
#endif

#if RCT_DEV
  if ([available count] == 0) {
    NSMutableString *message = [NSMutableString new];

    [message appendString:@"⚠  No permission handler detected.\n\n"];
    [message appendString:@"• Check that you link at least one permission handler in your Podfile.\n"];
    [message appendString:@"• Uninstall this app, delete your Xcode DerivedData folder and rebuild it.\n"];
    [message appendString:@"• If you use `use_frameworks!`, follow the workaround guide in the project README."];

    RCTLogError(@"%@", message);
  }
#endif

  return @{ @"available": available };
}

- (id<RNPermissionHandler> _Nullable)handlerForPermission:(RNPermission)permission {
  id<RNPermissionHandler> handler = nil;

  switch (permission) {
#if __has_include("RNPermissionHandlerCamera.h")
    case RNPermissionCamera:
      handler = [RNPermissionHandlerCamera new];
      break;
#endif
#if __has_include("RNPermissionHandlerLocationWhenInUse.h")
    case RNPermissionLocationWhenInUse:
      handler = [RNPermissionHandlerLocationWhenInUse new];
      break;
#endif
#if __has_include("RNPermissionHandlerMicrophone.h")
    case RNPermissionMicrophone:
      handler = [RNPermissionHandlerMicrophone new];
      break;
#endif
#if __has_include("RNPermissionHandlerAppTrackingTransparency.h")
    case RNPermissionAppTrackingTransparency:
      handler = [RNPermissionHandlerAppTrackingTransparency new];
      break;
#endif
    case RNPermissionUnknown:
      break; // RCTConvert prevents this case
  }

#if RCT_DEV
  for (NSString *key in [[handler class] usageDescriptionKeys]) {
    if (![[NSBundle mainBundle] objectForInfoDictionaryKey:key]) {
      RCTLogError(@"Cannot check or request permission without the required \"%@\" entry in your app \"Info.plist\" file", key);
      return nil;
    }
  }
#endif

  return handler;
}

- (NSString *)stringForStatus:(RNPermissionStatus)status {
  switch (status) {
    case RNPermissionStatusNotAvailable:
    case RNPermissionStatusRestricted:
      return @"unavailable";
    case RNPermissionStatusNotDetermined:
      return @"denied";
    case RNPermissionStatusDenied:
      return @"blocked";
    case RNPermissionStatusAuthorized:
      return @"granted";
  }
}

- (NSString *)lockHandler:(id<RNPermissionHandler>)handler {
  if (_handlers == nil) {
    _handlers = [NSMutableDictionary new];
  }

  NSString *lockId = [[NSUUID UUID] UUIDString];
  [_handlers setObject:handler forKey:lockId];

  return lockId;
}

- (void)unlockHandler:(NSString * _Nonnull)lockId {
  if (_handlers != nil) {
    [self.handlers removeObjectForKey:lockId];
  }
}

+ (bool)isFlaggedAsRequested:(NSString * _Nonnull)handlerId {
  NSArray<NSString *> *requested = [[NSUserDefaults standardUserDefaults] arrayForKey:SETTING_KEY];
  return requested == nil ? false : [requested containsObject:handlerId];
}

+ (void)flagAsRequested:(NSString * _Nonnull)handlerId {
  NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
  NSMutableArray *requested = [[userDefaults arrayForKey:SETTING_KEY] mutableCopy];

  if (requested == nil) {
    requested = [NSMutableArray new];
  }

  if (![requested containsObject:handlerId]) {
    [requested addObject:handlerId];
    [userDefaults setObject:requested forKey:SETTING_KEY];
    [userDefaults synchronize];
  }
}

RCT_REMAP_METHOD(openSettings,
                 openSettingsWithResolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject) {
  UIApplication *sharedApplication = [UIApplication sharedApplication];
  NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];

  if (@available(iOS 10.0, *)) {
    [sharedApplication openURL:url options:@{} completionHandler:^(BOOL success) {
      if (success) {
        resolve(@(true));
      } else {
        reject(@"cannot_open_settings", @"Cannot open application settings", nil);
      }
    }];
  } else {
    [sharedApplication openURL:url];
    resolve(@(true));
  }
}

RCT_REMAP_METHOD(check,
                 checkWithPermission:(RNPermission)permission
                 resolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject) {
  id<RNPermissionHandler> handler = [self handlerForPermission:permission];
  NSString *lockId = [self lockHandler:handler];

  [handler checkWithResolver:^(RNPermissionStatus status) {
    resolve([self stringForStatus:status]);
    [self unlockHandler:lockId];
  } rejecter:^(NSError *error) {
    reject([NSString stringWithFormat:@"%ld", (long)error.code], error.localizedDescription, error);
    [self unlockHandler:lockId];
  }];
}

RCT_REMAP_METHOD(request,
                 requestWithPermission:(RNPermission)permission
                 resolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject) {
  id<RNPermissionHandler> handler = [self handlerForPermission:permission];
  NSString *lockId = [self lockHandler:handler];

  [handler requestWithResolver:^(RNPermissionStatus status) {
    resolve([self stringForStatus:status]);
    [self unlockHandler:lockId];
  } rejecter:^(NSError *error) {
    reject([NSString stringWithFormat:@"%ld", (long)error.code], error.localizedDescription, error);
    [self unlockHandler:lockId];
  }];
}

@end
