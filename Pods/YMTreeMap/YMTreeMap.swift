//  Created by Adam Kaplan on 8/25/17.
//  Copyright 2017 Yahoo Holdings Inc.

import Foundation

@objc public class YMTreeMap: NSObject {

    /// A platform independent rectangle in cartesian coordinates. This is needed
    /// in order to support both macOS (NSRect) and iOS (CGRect).
    internal struct Rect {
        var x: Double
        var y: Double
        var width: Double
        var height: Double

        mutating func align(using alignment: FrameAlignment) {
            if alignment == .highPrecision {
                return
            }

            let maxX = x + width
            let maxY = y + height

            x = Rect.alignPoint(x, using: alignment)
            y = Rect.alignPoint(y, using: alignment)

            width = Rect.alignPoint(maxX, using: alignment) - x
            height = Rect.alignPoint(maxY, using: alignment) - y
        }

        static func alignPoint(_ point: Double, using alignment: FrameAlignment) -> Double {
            if alignment == .highPrecision {
                return point
            }

            let (integral, fractional) = modf(point)
            let subPixel = alignment == .retinaSubPixel

            if subPixel && fractional < 0.25 {
                return integral
            } else if fractional < 0.5 {
                return integral + 0.5
            } else if subPixel && fractional < 0.75 {
                return integral + 0.5
            } else {
                return integral + 1.0
            }
        }
    }

    enum LayoutDirection {
        // Prefer to layout along the horizontal axis first, then fall back to
        // vertical once the space is exhaused.
        case horizontal
        // Prefer to layout along the vertical axis first, then fall back to
        // horizontal once the space is exhaused.
        case vertical
    }

    enum TreeMapError: Error {
        case invalid
    }

    @objc public enum FrameAlignment: Int {
        /// High precision frames that accurately represent the relative weight
        /// of each item. This option is the fastest and most precise, but may
        /// result in blurry edges due to sub-pixel rendering.
        case highPrecision
        /// Frame origin and size values are rounded to the nearest 0.5. The
        /// relative weights are adjusted slightly to ensure that frames fall on
        /// typical pixel boundaries for Retina screens. Default.
        case retinaSubPixel
        /// Frame origin and size values are rounded to the nearest integral number.
        /// The relative weights are adjusted as needed to ensure that frames fall
        /// on pixel boundaries. This is suitable for non-retina screens.
        case integral
    }

    /// Set the alignment to apply to all generated TreeMap.Rects.
    @objc public var alignment = FrameAlignment.retinaSubPixel

    /// The tree map values provided during initialization
    @objc public let values: [Double]

    @objc lazy var allWeights: [Double] = {
        // Compute the total of all of the values
        let total = self.values.reduce(0) { $0 + $1 }

        // Map the values into their relative weight (percentage of total)
        return self.values.map { $0 / total }
    }()

    /// Initialize this tree map with a set of values as the basis for the areas
    /// of the tree map shapes. The numbers are arbitrary weights for items. The
    /// order of these values is preserved throughout all operations and return
    /// values. The list should be sorted using the preferred sort prior to
    /// initialization. Lists returned by any public method on YMTreeMap will
    /// always contain the same number of items as the `values` list provided here.
    ///
    /// - Parameter values: A list of positive double values
    @objc public init(withValues values: [Double]) {
        // Negative numbers are not supported or recoverable.
        values.forEach { (value) in
            if value < 0 {
                let exception = NSException(name: NSExceptionName.invalidArgumentException,
                            reason: "TreeMaps can not represent negative values: \(value)",
                    userInfo: nil)
                exception.raise()
            }
        }

        self.values = values
    }

    /// Convienance integer initializer for Swift clients. Since the values are
    /// summed and turned into relative floating point weights, calling this
    /// initializer is equivalent to casting all of the values to Double and
    /// calling init(withValues:)
    ///
    /// - Parameter values: A list of positive integers
    @nonobjc public convenience init(withValues values: [Int]) {
        self.init(withValues: values.map { Double($0) })
    }

    func tessellate(weights: [Double], inRect rect: Rect) -> [Rect] {
        // Convert weights into double array of pre-multipled area (as in length x width)
        // for faster access
        let rectArea = rect.width * rect.height
        var areas: [Double] = weights.map { $0 * rectArea }

        // Loop through each element and tessellate until all components used
        var rects = [Rect]()
        var canvas = rect

        while areas.count > 0 {
            var remainingCanvas: Rect  = canvas

            let newRects = self.tessellate(areas: areas, inRect: canvas, remaining: &remainingCanvas)

            // Add the new Rects to the list of all Rects, update the canvas
            // and remove the items from area that were used.
            rects.append(contentsOf: newRects)
            canvas = remainingCanvas
            areas.removeFirst(newRects.count)
        }

        return rects
    }

    func tessellate(areas: [Double], inRect rect: Rect, remaining: inout Rect) -> [Rect] {
        var direction: LayoutDirection // axis to fill along
        var length: Double // length of the constrained edge
        if rect.width >= rect.height {
            direction = .horizontal
            length = rect.height
        } else {
            direction = .vertical
            length = rect.width
        }

        // Try adding elements, testing aspect ratio each time. As long as the
        // aspect ratio decreases (nearer to 1:1), accept the element, otherwise
        // reject the new element.
        var aspectRatio: Double = Double.greatestFiniteMagnitude
        var groupWeightAccumulator: Double = 0
        var acceptedAreas = [Double]()
        for area: Double in areas {
            let worstAspectRatio = self.worstAspectRatio(forWeights: acceptedAreas,
                                                         groupWeight: groupWeightAccumulator,
                                                         proposedWeight: area,
                                                         withLength: length,
                                                         maxAspect: aspectRatio)

            // If the worst aspect of the row which includes the element under
            // test was better than the previous worst aspect, then accept this
            // new element into the row and test another element. Otherwise, this
            // row is complete & locked.
            if worstAspectRatio > aspectRatio {
                break
            } else {
                // Worst case aspect ratio has improved, so this is now the new
                // current aspect ratio!
                acceptedAreas.append(area)
                groupWeightAccumulator += area
                aspectRatio = worstAspectRatio
            }
        }

        // Compute the Rects for the used element weights
        let computedWidth: Double = groupWeightAccumulator / length
        var lengthOffset = direction == .horizontal ? rect.y : rect.x
        let rects = acceptedAreas.map { (area: Double) -> Rect in
            let height = area / computedWidth
            let thisOffset = lengthOffset
            lengthOffset += height

            var layoutRect: Rect
            switch direction {
            case .horizontal:
                layoutRect = Rect(x: rect.x, y: thisOffset, width: computedWidth, height: height)
            case .vertical:
                layoutRect = Rect(x: thisOffset, y: rect.y, width: height, height: computedWidth)
            }
            layoutRect.align(using: self.alignment)
            return layoutRect
        }

        // Compute the remaining rectangle for the the caller to pass to the next run
        switch direction {
        case .horizontal:
            remaining = Rect(x: rect.x + computedWidth,
                             y: rect.y,
                             width: rect.width - computedWidth,
                             height: rect.height)
        case .vertical:
            remaining = Rect(x: rect.x,
                             y: rect.y + computedWidth,
                             width: rect.width,
                             height: rect.height - computedWidth)
        }

        return rects
    }

    /// Compute the worst aspect ratio for the given array of weights. Each weight
    /// is converted into an area with one side of the specified length. The weight
    /// that produces the largest aspect ratio is chosed, and that aspect ratio
    /// is returned as the result.
    ///
    /// There are some non-obvious optimizations here:
    /// 1) The groupWeight can be derived by summing weights like: weights.reduce(0){$0+$1},
    /// however this operation increased runtime by 33% vs using a precomputed
    /// accumulated weight.
    /// 2) The proposed weight is not pre-merged into the array. This reduces the
    /// number of arrays that need to be allocated, could be 0 or lots depending
    /// on the data
    /// 3) A "stop" value is provided so that once an aspect ratio is encountered
    /// that is worse than the stop value, we'll just exit early.
    ///
    /// - Parameters:
    ///   - weights: The current weights that were already committed to
    ///   - groupWeight: The sum of all of the values in the weights array
    ///   - proposedWeight: The new proposed weight to check
    ///   - length: The length of the known side for the area rectangles
    /// - Returns: The worst aspect ratio encountered that is less than the stop
    /// limit
    func worstAspectRatio(forWeights weights: [Double],
                          groupWeight: Double,
                          proposedWeight: Double,
                          withLength length: Double,
                          maxAspect limit: Double) -> Double {
        // Find the new overall aspect ratio by combining all elements into
        // a single weighted meta-element. For this, we'll need to know the
        // weight of the new grouping.
        let computedGroupWeight = groupWeight + proposedWeight

        // Compute the length of the edge perpendicular to the edge that we're
        // laying out along for this group. Since we know the total area of the
        // group, and the length of one of it's edges - provided as an argument
        // to this method - we can easily find the length of the perpendicular
        // edge of this group
        //   ..........
        //   |        :
        //   |        :   1. User provides (L) via method argument
        // L |  Area  :   2. We compute (Area) by adding the areas of all items
        //   |        :   3. Using Area and L, we can extrapolate L'
        //   |________:
        //       L'
        let width = computedGroupWeight / length

        // Using the uniform "width" of the rectangle(s) in this area, compute
        // the lengths to get the aspect ratios. We want to find the WORST
        // aspect ratio in the group and test against that.
        var worstAspect = aspectRatio(width, proposedWeight / width)

        for weight in weights {
            let thisAspect = aspectRatio(width, weight / width)
            worstAspect = max(thisAspect, worstAspect)
            if worstAspect > limit {
                break
            }
        }

        return worstAspect
    }

    func aspectRatio(_ edge1: Double, _ edge2: Double) -> Double {
        return edge1 > edge2 ? edge1 / edge2 : edge2 / edge1
    }
}

// MARK: Platform Extensions for NSRect/CGRect

public extension YMTreeMap {

    #if os(iOS) || os(tvOS) || os(watchOS)
    public typealias SystemRect = CGRect
    #elseif os(OSX)
    public typealias SystemRect = NSRect
    #endif

    @objc public func tessellate(inRect rect: YMTreeMap.SystemRect) -> [YMTreeMap.SystemRect] {
        let rects = self.tessellate(weights: self.allWeights, inRect: rect.toYMTreeMapRect)
        return rects.map { $0.toSystemRect }
    }
}

internal extension YMTreeMap.Rect {
    internal var toSystemRect: YMTreeMap.SystemRect {
        return YMTreeMap.SystemRect(x: x, y: y, width: width, height: height)
    }
}

internal extension YMTreeMap.SystemRect {
    internal var toYMTreeMapRect: YMTreeMap.Rect {
        return YMTreeMap.Rect(x: Double(minX),
                              y: Double(minY),
                              width: Double(width),
                              height: Double(height))
    }
}
