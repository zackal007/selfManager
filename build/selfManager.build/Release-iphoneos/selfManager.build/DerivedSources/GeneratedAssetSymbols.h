#import <Foundation/Foundation.h>

#if __has_attribute(swift_private)
#define AC_SWIFT_PRIVATE __attribute__((swift_private))
#else
#define AC_SWIFT_PRIVATE
#endif

/// The resource bundle ID.
static NSString * const ACBundleID AC_SWIFT_PRIVATE = @"zack.selfManager";

/// The "AccentColor" asset catalog color resource.
static NSString * const ACColorNameAccentColor AC_SWIFT_PRIVATE = @"AccentColor";

/// The "AppBlue" asset catalog color resource.
static NSString * const ACColorNameAppBlue AC_SWIFT_PRIVATE = @"AppBlue";

/// The "AppGray" asset catalog color resource.
static NSString * const ACColorNameAppGray AC_SWIFT_PRIVATE = @"AppGray";

/// The "AppOrange" asset catalog color resource.
static NSString * const ACColorNameAppOrange AC_SWIFT_PRIVATE = @"AppOrange";

/// The "AppRed" asset catalog color resource.
static NSString * const ACColorNameAppRed AC_SWIFT_PRIVATE = @"AppRed";

/// The "Red" asset catalog color resource.
static NSString * const ACColorNameRed AC_SWIFT_PRIVATE = @"Red";

/// The "AppLogo" asset catalog image resource.
static NSString * const ACImageNameAppLogo AC_SWIFT_PRIVATE = @"AppLogo";

/// The "GoalBackground" asset catalog image resource.
static NSString * const ACImageNameGoalBackground AC_SWIFT_PRIVATE = @"GoalBackground";

/// The "GoalBackground2" asset catalog image resource.
static NSString * const ACImageNameGoalBackground2 AC_SWIFT_PRIVATE = @"GoalBackground2";

/// The "GoalBackground3" asset catalog image resource.
static NSString * const ACImageNameGoalBackground3 AC_SWIFT_PRIVATE = @"GoalBackground3";

/// The "GoalBackground4" asset catalog image resource.
static NSString * const ACImageNameGoalBackground4 AC_SWIFT_PRIVATE = @"GoalBackground4";

/// The "GoalBackground5" asset catalog image resource.
static NSString * const ACImageNameGoalBackground5 AC_SWIFT_PRIVATE = @"GoalBackground5";

/// The "GoalBackground6" asset catalog image resource.
static NSString * const ACImageNameGoalBackground6 AC_SWIFT_PRIVATE = @"GoalBackground6";

/// The "WelcomeBackground" asset catalog image resource.
static NSString * const ACImageNameWelcomeBackground AC_SWIFT_PRIVATE = @"WelcomeBackground";

#undef AC_SWIFT_PRIVATE
