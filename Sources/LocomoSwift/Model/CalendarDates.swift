//
//  CalendarDates.swift
//  RailMapAPI
//
//  Created by Jérémie Patot on 27/09/2024.
//

import Foundation

// MARK: CalendarDatesField

/// Enum pour les champs du fichier `calendar_dates.txt`
public enum CalendarDatesField: String, Hashable, KeyPathVending, Sendable {
    case serviceID = "service_id"
    case date = "date"
    case exceptionType = "exception_type"
    /// Used when a nonstandard field is found within a GTFS feed.
    case nonstandard = "nonstandard"
    
    internal var path: AnyKeyPath {
        switch self {
        case .serviceID: return \CalendarDate.serviceID
        case .date: return \CalendarDate.date
        case .exceptionType: return \CalendarDate.exceptionType
        case .nonstandard: return \CalendarDate.nonstandard
        }
    }
}

// MARK: - CalendarDate

/// Représente une exception de service pour une date donnée
public struct CalendarDate: Hashable, Identifiable, Sendable {
    public var id = UUID()  // Propriété initialisée
    public var serviceID: LSID
    public var date: Date
    public var exceptionType: Int
    public var nonstandard: String? = nil
    
    public init(serviceID: String, date: Date, exceptionType: Int) {
        self.serviceID = serviceID
        self.date = date
        self.exceptionType = exceptionType
    }
    
    /// Initialisation à partir d'un enregistrement du fichier GTFS
    public init(from record: String, using headerFields: [CalendarDatesField]) throws {
        // Initialisation des propriétés avec des valeurs par défaut
        self.id = UUID()  // Assurez-vous que l'id est initialisé
        self.serviceID = ""
        self.date = Date()
        self.exceptionType = 0

        let fields = try record.readRecord()
        if fields.count != headerFields.count {
            throw LSError.headerRecordMismatch
        }
        
        for (index, header) in headerFields.enumerated() {
            let field = fields[index]
            switch header {
            case .serviceID:
                self.serviceID = field
            case .date:
                if let parsedDate = CalendarDate.dateFormatter.date(from: field) {
                    self.date = parsedDate
                } else {
                    throw LSError.invalidFieldType
                }
            case .exceptionType:
                self.exceptionType = Int(field) ?? 0
            case .nonstandard:
                continue
            }
        }
    }
    
    /// Formatteur de date pour les champs `date`
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        return formatter
    }()
}

// MARK: - CalendarDates

/// Un ensemble d'exceptions de service pour différentes dates
public struct CalendarDates: Identifiable, RandomAccessCollection, Sendable {
    public var id = UUID()
    public var startIndex: Int { return dates.startIndex }
    public var endIndex: Int { return dates.endIndex }
    
    public var headerFields: [CalendarDatesField] = []
    public var dates: [CalendarDate] = []
    
    public subscript(index: Int) -> CalendarDate {
        return dates[index]
    }
    
    mutating func add(_ date: CalendarDate) {
        dates.append(date)
    }
    
    mutating func remove(_ date: CalendarDate) {
        if let index = dates.firstIndex(of: date) {
            dates.remove(at: index)
        }
    }
    
    init<S: Sequence>(_ sequence: S)
    where S.Iterator.Element == CalendarDate {
      for date in sequence {
        self.add(date)
      }
    }
    
    /// Initialisation à partir d'un fichier GTFS
    public init(from url: URL) throws {
        let records = try String(contentsOf: url).splitRecords()
        
        if records.count <= 1 { return }
        let headerRecord = String(records[0])
        self.headerFields = try headerRecord.readHeader()
        
        self.dates.reserveCapacity(records.count - 1)
        for dateRecord in records.dropFirst() {
            let calendarDate = try CalendarDate(from: String(dateRecord), using: headerFields)
            self.add(calendarDate)
        }
    }
}

extension CalendarDates: Sequence {

    public typealias Iterator = IndexingIterator<[CalendarDate]>

  public func makeIterator() -> Iterator {
    return dates.makeIterator()
  }

}

extension CalendarDates {
    init(_ calendarDates: [CalendarDate]) {
        self.dates = calendarDates
    }
}
