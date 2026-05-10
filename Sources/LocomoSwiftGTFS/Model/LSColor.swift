//
//  LSColor.swift
//  LocomoSwiftGTFS
//
//  Portable RGBA color type that works on every platform LocomoSwift
//  supports — including Linux, where CoreGraphics is not available.
//  On Apple platforms an `LSColor` can be converted to `CGColor` via the
//  `cgColor` convenience exposed in the `#if canImport(CoreGraphics)` block.
//

import Foundation

public struct LSColor: Hashable, Sendable {
    /// Red component, in the range 0.0 - 1.0.
    public let red: Double
    /// Green component, in the range 0.0 - 1.0.
    public let green: Double
    /// Blue component, in the range 0.0 - 1.0.
    public let blue: Double
    /// Alpha component, in the range 0.0 - 1.0. Defaults to fully opaque.
    public let alpha: Double

    public init(red: Double, green: Double, blue: Double, alpha: Double = 1.0) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }
}

#if canImport(CoreGraphics)
import CoreGraphics

extension LSColor {
    /// `CGColor` bridge for Apple platforms.
    ///
    /// Available only when CoreGraphics can be imported (iOS, macOS, tvOS,
    /// watchOS, Mac Catalyst). On Linux and other CoreGraphics-less
    /// platforms, work directly with the RGBA components instead.
    public var cgColor: CGColor {
        CGColor(
            colorSpace: CGColorSpaceCreateDeviceRGB(),
            components: [CGFloat(red), CGFloat(green), CGFloat(blue), CGFloat(alpha)]
        )!
    }
}
#endif
