//
//  StopTimes.swift
//  RailMapAPI
//
//  Created by Jérémie Patot on 20/09/2024.
//

import Foundation

// MARK: StopTimeField

/// Describes the various fields found within a ``Route`` record or header.
///
/// `StopTimeField`s are generally members of `Set`s that enumerate
/// the fields found within a ``StopTime`` record or header. The following,
/// for example, returns the `Set` of route fields found within
/// the `myStopTimes` feed header:
/// ```swift
///   let fields = myStopTimes.headerFields
/// ```
///
/// Should you need it, use `rawValue` to obtain the GTFS stop time field name
/// associated with an `StopTimeField` value as a `String`:
/// ```swift
///   let gtfsField = StopTimeField.details.rawValue  //  Returns "route_desc"
/// ```
public enum StopTimeField: String, Hashable, KeyPathVending {
    /// Trip ID field.
    case tripID = "trip_id"
    /// Trip arrival field.
    case arrival = "arrival_time"
    /// Trip departure field.
    case departure = "departure_time"
    /// Stop ID field.
    case stopID = "stop_id"
    /// Stop sequence number field.
    case stopSequenceNumber = "stop_sequence"
    /// Stop heading sign field.
    case stopHeadingSign = "stop_headsign"
    /// Stop pickup type field.
    case pickupType = "pickup_type"
    /// Stop drop off type field.
    case dropOffType = "drop_off_type"
    /// Stop continuous pickup field.
    case continuousPickup = "continuous_pickup"
    /// Stop continuous drop off field.
    case continuousDropOff = "continuous_drop_off"
    /// Stop distance traveled for shape field.
    case distanceTraveledForShape = "shape_dist_traveled"
    /// Stop time point type field.
    case timePointType = "timepoint"
    /// Used when a nonstandard field is found within a GTFS feed.
    case nonstandard = "nonstandard"
    
    internal var path: AnyKeyPath {
        switch self {
        case .tripID: return \StopTime.tripID
        case .arrival: return \StopTime.arrival
        case .departure: return \StopTime.departure
        case .stopID: return \StopTime.stopID
        case .stopSequenceNumber: return \StopTime.stopSequenceNumber
        case .stopHeadingSign: return \StopTime.stopHeadingSign
        case .pickupType: return \StopTime.pickupType
        case .dropOffType: return \StopTime.dropOffType
        case .continuousPickup: return \StopTime.continuousPickup
        case .continuousDropOff: return \StopTime.continuousDropOff
        case .distanceTraveledForShape: return \StopTime.distanceTraveledForShape
        case .timePointType: return \StopTime.timePointType
        case .nonstandard: return \StopTime.nonstandard
        }
    }
}

// MARK: - StopTime

/// A representation of a single StopTime record.
public struct StopTime: Hashable, Identifiable {
    public var id = UUID()
    public var tripID: LSID = ""
    public var arrival: Date?
    public var departure: Date?
    public var stopID: LSID = ""
    public var stopSequenceNumber: UInt = 0
    public var stopHeadingSign: String?
    public var pickupType: Int?
    public var dropOffType: Int?
    public var continuousPickup: Int?
    public var continuousDropOff: Int?
    public var distanceTraveledForShape: Double?
    public var timePointType: Int?
    public var nonstandard: String? = nil
    
    public let timeZone: TimeZone
    
    public init(
        tripID: LSID = "",
        arrival: Date? = nil,
        departure: Date? = nil,
        stopID: LSID = "",
        stopSequenceNumber: UInt = 0,
        stopHeadingSign: String? = nil,
        pickupType: Int? = nil,
        dropOffType: Int? = nil,
        continuousPickup: Int? = nil,
        continuousDropOff: Int? = nil,
        distanceTraveledForShape: Double? = nil,
        timePointType: Int? = nil,
        timeZone: TimeZone? = TimeZone(secondsFromGMT: 0)!
    ) {
        self.tripID = tripID
        self.arrival = arrival
        self.departure = departure
        self.stopID = stopID
        self.stopSequenceNumber = stopSequenceNumber
        self.stopHeadingSign = stopHeadingSign
        self.pickupType = pickupType
        self.dropOffType = dropOffType
        self.continuousPickup = continuousPickup
        self.continuousDropOff = continuousDropOff
        self.distanceTraveledForShape = distanceTraveledForShape
        self.timePointType = timePointType
        self.timeZone = timeZone!
    }
    
    init(
        from record: String,
        using headers: [StopTimeField],
        timeZone: TimeZone
    ) throws {
        self.timeZone = timeZone
        
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        
        do {
            let fields = try record.readRecord()
            if fields.count != headers.count {
                throw LSError.headerRecordMismatch
            }
            for (index, header) in headers.enumerated() {
                let field = fields[index]
                switch header {
                case .tripID, .stopID:
                    try field.assignStringTo(&self, for: header)
                case .arrival:
                    self.arrival = timeStringToHour(field)
                case .departure:
                    self.departure = timeStringToHour(field)
                case .stopHeadingSign:
                    try field.assignOptionalStringTo(&self, for: header)
                case .stopSequenceNumber:
                    try field.assignUIntTo(&self, for: header)
                case .pickupType:
                    if let pickupTypeValue = Int(field) {
                        self.pickupType = pickupTypeValue
                    }
                case .dropOffType:
                    if let dropOffTypeValue = Int(field) {
                        self.dropOffType = dropOffTypeValue
                    }
                case .continuousPickup:
                    if let continuousPickupValue = Int(field) {
                        self.continuousPickup = continuousPickupValue
                    }
                case .continuousDropOff:
                    if let continuousDropOffValue = Int(field) {
                        self.continuousDropOff = continuousDropOffValue
                    }
                case .nonstandard:
                    try field.assignStringTo(&self, for: header)
                default:
                    continue
                }
            }
        } catch let error {
            throw error
        }
    }
    
    private func timeStringToHour(_ timeString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = self.timeZone
        
        // Create base date components
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = self.timeZone
        
        guard let parsedDate = formatter.date(from: timeString) else { return nil }
        
        // Extract only time components
        let components = calendar.dateComponents([.hour, .minute, .second], from: parsedDate)
        
        // Create reference date (2000-01-01) with the correct time
        var referenceComponents = DateComponents()
        referenceComponents.year = 2000
        referenceComponents.month = 1
        referenceComponents.day = 1
        referenceComponents.hour = components.hour
        referenceComponents.minute = components.minute
        referenceComponents.second = components.second
        
        return calendar.date(from: referenceComponents)
    }
}

extension StopTime: Equatable {
    public static func == (lhs: StopTime, rhs: StopTime) -> Bool {
        return
        lhs.tripID == rhs.tripID &&
        lhs.stopID == rhs.stopID
    }
}

extension StopTime: CustomStringConvertible {
    public var description: String {
        return "StopTime: \(self.tripID) \(self.stopID)"
    }
}

// MARK: - StopTimes

/// - Tag: StopTimes
public struct StopTimes: Identifiable {
    public let id = UUID()
    public var headerFields = [StopTimeField]()
    public var stopTimes = [StopTime]()
    
    subscript(index: Int) -> StopTime {
        get {
            return stopTimes[index]
        }
        set(newValue) {
            stopTimes[index] = newValue
        }
    }
    
    mutating func add(_ stopTime: StopTime) {
        // TODO: Add to header fields supported by this collection
        self.stopTimes.append(stopTime)
    }
    
    mutating func remove(_ stopTime: StopTime) {
    }
    
    init<S: Sequence>(_ sequence: S)
    where S.Iterator.Element == StopTime {
        for stopTime in sequence {
            self.add(stopTime)
        }
    }
    
    init(from url: URL, timeZone: TimeZone) throws {
        do {
            let records = try String(contentsOf: url).splitRecords()
            
            if records.count < 1 { return }
            let headerRecord = String(records[0])
            self.headerFields = try headerRecord.readHeader()
            
            self.stopTimes.reserveCapacity(records.count - 1)
            for stopTimeRecord in records[1 ..< records.count] {
                let stopTime = try StopTime(from: String(stopTimeRecord),
                                            using: headerFields, timeZone: timeZone)
                self.add(stopTime)
            }
        } catch let error {
            throw error
        }
    }
}

extension StopTimes: Sequence {
    public typealias Iterator = IndexingIterator<[StopTime]>
    
    public func makeIterator() -> Iterator {
        return stopTimes.makeIterator()
    }
}

extension StopTimes {
    public init(_ stopTimes: [StopTime]) {
        self.stopTimes = stopTimes
    }
}
