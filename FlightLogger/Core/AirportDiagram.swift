import Foundation

/// A schematic of an airfield: runways, taxiways and aprons, as lines and
/// polygons over the moving map.
///
/// Every coordinate is a [latitude, longitude] pair, the order most airfield
/// datasets publish. Runway ends in the bundled file come from the OurAirports
/// dataset, which is public domain. Taxiways and aprons are not in that dataset;
/// they are added only from a source the pilot can cite, and until then the
/// screen says they are missing rather than drawing them from memory.
struct AirportDiagram: Codable, Equatable, Sendable {

    var code: String
    var name: String
    /// Where the geometry came from. Shown on screen.
    var source: String
    var runways: [Runway]
    var taxiways: [Taxiway]
    var aprons: [Area]

    struct Runway: Codable, Equatable, Sendable {
        var designator: String
        var ends: [[Double]]
    }

    struct Taxiway: Codable, Equatable, Sendable {
        var name: String
        var points: [[Double]]
    }

    struct Area: Codable, Equatable, Sendable {
        var name: String
        var polygon: [[Double]]
    }

    /// A [latitude, longitude] pair as a coordinate; nil when the pair is malformed.
    static func coordinate(_ pair: [Double]) -> Coordinate? {
        guard pair.count == 2 else { return nil }
        return Coordinate(latitude: pair[0], longitude: pair[1])
    }
}

/// Loads the bundled schematics and finds the one for a field.
enum AirportDiagrams {

    static func load(bundle: Bundle = .main) -> [AirportDiagram] {
        guard let url = bundle.url(forResource: "airport-diagrams", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return [] }
        return decode(data)
    }

    /// Broken data gives an empty list, never a crash: a missing schematic is
    /// a worse outcome than no schematic on a screen the pilot may be reading.
    static func decode(_ data: Data) -> [AirportDiagram] {
        (try? JSONDecoder().decode([AirportDiagram].self, from: data)) ?? []
    }

    static func diagram(for code: String?, in list: [AirportDiagram]) -> AirportDiagram? {
        guard let code else { return nil }
        return list.first { $0.code == code }
    }
}
