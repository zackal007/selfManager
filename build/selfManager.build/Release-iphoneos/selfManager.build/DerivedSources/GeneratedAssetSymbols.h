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

/// The "Blue" asset catalog color resource.
static NSString * const ACColorNameBlue AC_SWIFT_PRIVATE = @"Blue";

/// The "Gray" asset catalog color resource.
static NSString * const ACColorNameGray AC_SWIFT_PRIVATE = @"Gray";

/// The "Orange" asset catalog color resource.
static NSString * const ACColorNameOrange AC_SWIFT_PRIVATE = @"Orange";

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
