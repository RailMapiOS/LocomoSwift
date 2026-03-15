//
//  LocomoSwift.swift
//  LocomoSwift
//
//  Umbrella module — re-exports both sub-modules.
//
//  Usage:
//    import LocomoSwift        → everything (GTFS Static + Realtime)
//    import LocomoSwiftGTFS    → GTFS Static only
//    import LocomoSwiftRT      → GTFS Realtime only
//

@_exported import LocomoSwiftGTFS
@_exported import LocomoSwiftRT
