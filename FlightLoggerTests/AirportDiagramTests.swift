import XCTest
@testable import FlightLogger

/// The schematic loader: what it decodes, what it refuses, and the runway
/// geometry it hands the map.
final class AirportDiagramTests: XCTestCase {

    private let json = """
    [{"code":"LKTB","name":"Brno-Tuřany","source":"test",
      "runways":[{"designator":"08/26","ends":[[49.151299,16.685686],[49.150379,16.696522]]}],
      "taxiways":[],"aprons":[]}]
    """

    func testDecodesAndFindsTheFieldByCode() {
        let list = AirportDiagrams.decode(Data(json.utf8))
        XCTAssertEqual(list.count, 1)
        XCTAssertNotNil(AirportDiagrams.diagram(for: "LKTB", in: list))
        XCTAssertNil(AirportDiagrams.diagram(for: "LKPR", in: list))
        XCTAssertNil(AirportDiagrams.diagram(for: nil, in: list))
    }

    /// Runway 08/26 is 2 624 ft, which is about 800 m. The endpoints have to
    /// describe that runway, not some other stretch of the field.
    func testRunwayEndsDescribeTheRunwayInTheDataset() {
        let list = AirportDiagrams.decode(Data(json.utf8))
        let ends = list[0].runways[0].ends.compactMap(AirportDiagram.coordinate)
        XCTAssertEqual(ends.count, 2)
        XCTAssertEqual(GeoMath.distance(ends[0], ends[1]), 800, accuracy: 20)
    }

    func testAMalformedPairIsRejected() {
        XCTAssertNil(AirportDiagram.coordinate([49.1]))
        XCTAssertNil(AirportDiagram.coordinate([49.1, 16.6, 1]))
    }

    func testBrokenJSONGivesNothingRatherThanCrashing() {
        XCTAssertTrue(AirportDiagrams.decode(Data("not json".utf8)).isEmpty)
    }
}
