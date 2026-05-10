//
//  Shape.swift
//  LocomoSwift
//
//  Created by Jérémie Patot on 15/03/2026.
//

import Foundation

// MARK: ShapeField

/// Describes the various fields found within a ``ShapePoint`` record or header.
///
/// `ShapeField`s are generally members of arrays that enumerate
/// the fields found within a ``ShapePoint`` record or header. The following,
/// for example, returns the array of shape fields found within
/// the `myShapes` feed header:
/// ```swift
///   let fields = myShapes.headerFields
/// ```
///
/// Use `rawValue` to obtain the GTFS shape field name
/// associated with a `ShapeField` value as a `String`:
/// ```swift
///   let gtfsField = ShapeField.shapeID.rawValue  //  Returns "shape_id"
/// ```
public enum ShapeField: String, Hashable, KeyPathVending, Sendable {
    /// Shape ID field.
    case shapeID = "shape_id"
    /// Shape point latitude field.
    case latitude = "shape_pt_lat"
    /// Shape point longitude field.
    case longitude = "shape_pt_lon"
    /// Shape point sequence field.
    case sequence = "shape_pt_sequence"
    /// Shape distance traveled field (optional).
    case distanceTraveled = "shape_dist_traveled"
    /// Used when a nonstandard field is found within a GTFS feed.
    case nonstandard = "nonstandard"

    internal var path: AnyKeyPath {
        switch self {
        case .shapeID: return \ShapePoint.shapeID
        case .latitude: return \ShapePoint.latitude
        case .longitude: return \ShapePoint.longitude
        case .sequence: return \ShapePoint.sequence
        case .distanceTraveled: return \ShapePoint.distanceTraveled
        case .nonstandard: return \ShapePoint.nonstandard
        }
    }
}

// MARK: - ShapePoint

/// A representation of a single point in a GTFS shape.
public struct ShapePoint: Hashable, Identifiable {
    public let id = UUID()
    public var shapeID: LSID = ""
    public var latitude: Double?
    public var longitude: Double?
    public var sequence: UInt = 0
    public var distanceTraveled: Double?
    public var nonstandard: String? = nil

    public init(
        shapeID: LSID = "",
        latitude: Double? = nil,
        longitude: Double? = nil,
        sequence: UInt = 0,
        distanceTraveled: Double? = nil
    ) {
        self.shapeID = shapeID
        self.latitude = latitude
        self.longitude = longitude
        self.sequence = sequence
        self.distanceTraveled = distanceTraveled
    }

    init(from record: String, using headers: [ShapeField]) throws {
        do {
            let fields = try record.readRecord()
            if fields.count != headers.count {
                throw LSError.headerRecordMismatch
            }
            for (index, header) in headers.enumerated() {
                let field = fields[index]
                switch header {
                case .shapeID:
                    try field.assignStringTo(&self, for: header)
                case .latitude, .longitude:
                    try field.assignOptionalDoubleTo(&self, for: header)
                case .sequence:
                    try field.assignUIntTo(&self, for: header)
                case .distanceTraveled:
                    if let value = Double(field) {
                        self.distanceTraveled = value
                    }
                case .nonstandard:
                    continue
                }
            }
        } catch let error {
            throw error
        }
    }
}

extension ShapePoint: Equatable {
    public static func == (lhs: ShapePoint, rhs: ShapePoint) -> Bool {
        return
            lhs.shapeID == rhs.shapeID &&
            lhs.sequence == rhs.sequence
    }
}

extension ShapePoint: CustomStringConvertible {
    public var description: String {
        return "ShapePoint: \(self.shapeID) seq=\(self.sequence) (\(self.latitude ?? 0), \(self.longitude ?? 0))"
    }
}

// MARK: - Shapes

/// A collection of shape points parsed from a GTFS shapes.txt file.
///
/// - Tag: Shapes
public struct Shapes: Identifiable {
    public let id = UUID()
    public var headerFields = [ShapeField]()
    public var points = [ShapePoint]()

    subscript(index: Int) -> ShapePoint {
        get {
            return points[index]
        }
        set(newValue) {
            points[index] = newValue
        }
    }

    mutating func add(_ point: ShapePoint) {
        self.points.append(point)
    }

    mutating func remove(_ point: ShapePoint) {
        self.points.removeAll { $0 == point }
    }

    init<S: Sequence>(_ sequence: S)
    where S.Iterator.Element == ShapePoint {
        for point in sequence {
            self.add(point)
        }
    }

    /// Initialize shapes dataset from a CSV string.
    public init(from content: String) throws {
        let records = content.splitRecords()

        if records.count < 1 { return }
        let headerRecord = String(records[0])
        self.headerFields = try headerRecord.readHeader()

        self.points.reserveCapacity(records.count - 1)
        for shapeRecord in records[1 ..< records.count] {
            let point = try ShapePoint(from: String(shapeRecord), using: headerFields)
            self.add(point)
        }
    }

    /// Initialize shapes dataset from file.
    public init(from url: URL) throws {
        try self.init(from: String(contentsOf: url, encoding: .utf8))
    }

    /// Returns all points for a given shape ID, sorted by sequence number.
    public func pointsForShape(_ shapeID: String) -> [ShapePoint] {
        return points
            .filter { $0.shapeID == shapeID }
            .sorted { $0.sequence < $1.sequence }
    }

    /// Returns all unique shape IDs in this collection.
    public var shapeIDs: Set<String> {
        Set(points.map { $0.shapeID })
    }
}

extension Shapes: Sequence {
    public typealias Iterator = IndexingIterator<[ShapePoint]>

    public func makeIterator() -> Iterator {
        return points.makeIterator()
    }
}

extension Shapes {
    public init(_ points: [ShapePoint]) {
        self.points = points
    }
}
