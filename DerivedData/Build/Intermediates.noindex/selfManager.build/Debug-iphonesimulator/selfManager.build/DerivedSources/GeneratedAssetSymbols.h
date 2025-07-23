#import <Foundation/Foundation.h>

#if __has_attribute(swift_private)
#define AC_SWIFT_PRIVATE __attribute__((swift_private))
#else
#define AC_SWIFT_PRIVATE
#endif

/// The "GoalBackground" asset catalog image resource.
static NSString * const ACImageNameGoalBackground AC_SWIFT_PRIVATE = @"GoalBackground";

/// The "GoalBackground2" asset catalog image resource.
static NSString * const ACImageNameGoalBackground2 AC_SWIFT_PRIVATE = @"GoalBackground2";

#undef AC_SWIFT_PRIVATE
