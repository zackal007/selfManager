import Foundation
#if canImport(AppKit)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif
#if canImport(SwiftUI)
import SwiftUI
#endif
#if canImport(DeveloperToolsSupport)
import DeveloperToolsSupport
#endif

#if SWIFT_PACKAGE
private let resourceBundle = Foundation.Bundle.module
#else
private class ResourceBundleClass {}
private let resourceBundle = Foundation.Bundle(for: ResourceBundleClass.self)
#endif

// MARK: - Color Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ColorResource {

    /// The "AccentColor" asset catalog color resource.
    static let accent = DeveloperToolsSupport.ColorResource(name: "AccentColor", bundle: resourceBundle)

    /// The "AppBlue" asset catalog color resource.
    static let appBlue = DeveloperToolsSupport.ColorResource(name: "AppBlue", bundle: resourceBundle)

    /// The "AppGray" asset catalog color resource.
    static let appGray = DeveloperToolsSupport.ColorResource(name: "AppGray", bundle: resourceBundle)

    /// The "AppOrange" asset catalog color resource.
    static let appOrange = DeveloperToolsSupport.ColorResource(name: "AppOrange", bundle: resourceBundle)

    /// The "AppRed" asset catalog color resource.
    static let appRed = DeveloperToolsSupport.ColorResource(name: "AppRed", bundle: resourceBundle)

    /// The "Red" asset catalog color resource.
    static let red = DeveloperToolsSupport.ColorResource(name: "Red", bundle: resourceBundle)

}

// MARK: - Image Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ImageResource {

    /// The "AppLogo" asset catalog image resource.
    static let appLogo = DeveloperToolsSupport.ImageResource(name: "AppLogo", bundle: resourceBundle)

    /// The "GoalBackground" asset catalog image resource.
    static let goalBackground = DeveloperToolsSupport.ImageResource(name: "GoalBackground", bundle: resourceBundle)

    /// The "GoalBackground2" asset catalog image resource.
    static let goalBackground2 = DeveloperToolsSupport.ImageResource(name: "GoalBackground2", bundle: resourceBundle)

    /// The "GoalBackground3" asset catalog image resource.
    static let goalBackground3 = DeveloperToolsSupport.ImageResource(name: "GoalBackground3", bundle: resourceBundle)

    /// The "GoalBackground4" asset catalog image resource.
    static let goalBackground4 = DeveloperToolsSupport.ImageResource(name: "GoalBackground4", bundle: resourceBundle)

    /// The "GoalBackground5" asset catalog image resource.
    static let goalBackground5 = DeveloperToolsSupport.ImageResource(name: "GoalBackground5", bundle: resourceBundle)

    /// The "GoalBackground6" asset catalog image resource.
    static let goalBackground6 = DeveloperToolsSupport.ImageResource(name: "GoalBackground6", bundle: resourceBundle)

    /// The "WelcomeBackground" asset catalog image resource.
    static let welcomeBackground = DeveloperToolsSupport.ImageResource(name: "WelcomeBackground", bundle: resourceBundle)

}

// MARK: - Color Symbol Extensions -

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSColor {

    /// The "AccentColor" asset catalog color.
    static var accent: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .accent)
#else
        .init()
#endif
    }

    /// The "AppBlue" asset catalog color.
    static var appBlue: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .appBlue)
#else
        .init()
#endif
    }

    /// The "AppGray" asset catalog color.
    static var appGray: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .appGray)
#else
        .init()
#endif
    }

    /// The "AppOrange" asset catalog color.
    static var appOrange: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .appOrange)
#else
        .init()
#endif
    }

    /// The "AppRed" asset catalog color.
    static var appRed: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .appRed)
#else
        .init()
#endif
    }

    #warning("The \"Red\" color asset name resolves to a conflicting NSColor symbol \"red\". Try renaming the asset.")

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

    /// The "AccentColor" asset catalog color.
    static var accent: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .accent)
#else
        .init()
#endif
    }

    /// The "AppBlue" asset catalog color.
    static var appBlue: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .appBlue)
#else
        .init()
#endif
    }

    /// The "AppGray" asset catalog color.
    static var appGray: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .appGray)
#else
        .init()
#endif
    }

    /// The "AppOrange" asset catalog color.
    static var appOrange: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .appOrange)
#else
        .init()
#endif
    }

    /// The "AppRed" asset catalog color.
    static var appRed: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .appRed)
#else
        .init()
#endif
    }

    #warning("The \"Red\" color asset name resolves to a conflicting UIColor symbol \"red\". Try renaming the asset.")

}
#endif

#if canImport(SwiftUI)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.Color {

    /// The "AccentColor" asset catalog color.
    static var accent: SwiftUI.Color { .init(.accent) }

    /// The "AppBlue" asset catalog color.
    static var appBlue: SwiftUI.Color { .init(.appBlue) }

    /// The "AppGray" asset catalog color.
    static var appGray: SwiftUI.Color { .init(.appGray) }

    /// The "AppOrange" asset catalog color.
    static var appOrange: SwiftUI.Color { .init(.appOrange) }

    /// The "AppRed" asset catalog color.
    static var appRed: SwiftUI.Color { .init(.appRed) }

    #warning("The \"Red\" color asset name resolves to a conflicting Color symbol \"red\". Try renaming the asset.")

}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {

    /// The "AccentColor" asset catalog color.
    static var accent: SwiftUI.Color { .init(.accent) }

    /// The "AppBlue" asset catalog color.
    static var appBlue: SwiftUI.Color { .init(.appBlue) }

    /// The "AppGray" asset catalog color.
    static var appGray: SwiftUI.Color { .init(.appGray) }

    /// The "AppOrange" asset catalog color.
    static var appOrange: SwiftUI.Color { .init(.appOrange) }

    /// The "AppRed" asset catalog color.
    static var appRed: SwiftUI.Color { .init(.appRed) }

}
#endif

// MARK: - Image Symbol Extensions -

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSImage {

    /// The "AppLogo" asset catalog image.
    static var appLogo: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .appLogo)
#else
        .init()
#endif
    }

    /// The "GoalBackground" asset catalog image.
    static var goalBackground: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .goalBackground)
#else
        .init()
#endif
    }

    /// The "GoalBackground2" asset catalog image.
    static var goalBackground2: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .goalBackground2)
#else
        .init()
#endif
    }

    /// The "GoalBackground3" asset catalog image.
    static var goalBackground3: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .goalBackground3)
#else
        .init()
#endif
    }

    /// The "GoalBackground4" asset catalog image.
    static var goalBackground4: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .goalBackground4)
#else
        .init()
#endif
    }

    /// The "GoalBackground5" asset catalog image.
    static var goalBackground5: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .goalBackground5)
#else
        .init()
#endif
    }

    /// The "GoalBackground6" asset catalog image.
    static var goalBackground6: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .goalBackground6)
#else
        .init()
#endif
    }

    /// The "WelcomeBackground" asset catalog image.
    static var welcomeBackground: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .welcomeBackground)
#else
        .init()
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

    /// The "AppLogo" asset catalog image.
    static var appLogo: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .appLogo)
#else
        .init()
#endif
    }

    /// The "GoalBackground" asset catalog image.
    static var goalBackground: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .goalBackground)
#else
        .init()
#endif
    }

    /// The "GoalBackground2" asset catalog image.
    static var goalBackground2: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .goalBackground2)
#else
        .init()
#endif
    }

    /// The "GoalBackground3" asset catalog image.
    static var goalBackground3: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .goalBackground3)
#else
        .init()
#endif
    }

    /// The "GoalBackground4" asset catalog image.
    static var goalBackground4: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .goalBackground4)
#else
        .init()
#endif
    }

    /// The "GoalBackground5" asset catalog image.
    static var goalBackground5: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .goalBackground5)
#else
        .init()
#endif
    }

    /// The "GoalBackground6" asset catalog image.
    static var goalBackground6: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .goalBackground6)
#else
        .init()
#endif
    }

    /// The "WelcomeBackground" asset catalog image.
    static var welcomeBackground: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .welcomeBackground)
#else
        .init()
#endif
    }

}
#endif

// MARK: - Thinnable Asset Support -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
@available(watchOS, unavailable)
extension DeveloperToolsSupport.ColorResource {

    private init?(thinnableName: Swift.String, bundle: Foundation.Bundle) {
#if canImport(AppKit) && os(macOS)
        if AppKit.NSColor(named: NSColor.Name(thinnableName), bundle: bundle) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#elseif canImport(UIKit) && !os(watchOS)
        if UIKit.UIColor(named: thinnableName, in: bundle, compatibleWith: nil) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSColor {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
#if !targetEnvironment(macCatalyst)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
#if !os(watchOS)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(SwiftUI)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.Color {

    private init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
        if let resource = thinnableResource {
            self.init(resource)
        } else {
            return nil
        }
    }

}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {

    private init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
        if let resource = thinnableResource {
            self.init(resource)
        } else {
            return nil
        }
    }

}
#endif

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
@available(watchOS, unavailable)
extension DeveloperToolsSupport.ImageResource {

    private init?(thinnableName: Swift.String, bundle: Foundation.Bundle) {
#if canImport(AppKit) && os(macOS)
        if bundle.image(forResource: NSImage.Name(thinnableName)) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#elseif canImport(UIKit) && !os(watchOS)
        if UIKit.UIImage(named: thinnableName, in: bundle, compatibleWith: nil) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSImage {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ImageResource?) {
#if !targetEnvironment(macCatalyst)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ImageResource?) {
#if !os(watchOS)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

