import XCTest

@testable import Vendor_Locator

final class DataParserImplTests: XCTestCase {
    private struct Record: Decodable, Equatable {
        let name: String
        let createdAt: Date
    }

    func testParsesISO8601ByDefault() throws {
        let data = Data(#"{"name":"Example","createdAt":"1970-01-01T00:00:00Z"}"#.utf8)
        let result = try DataParserImpl().parse(data, as: Record.self)
        XCTAssertEqual(result, Record(name: "Example", createdAt: Date(timeIntervalSince1970: 0)))
    }

    func testAcceptsExplicitDateStrategy() throws {
        let data = Data(#"{"name":"Example","createdAt":123}"#.utf8)
        let result = try DataParserImpl(dateDecodingStrategy: .secondsSince1970)
            .parse(data, as: Record.self)
        XCTAssertEqual(result.createdAt, Date(timeIntervalSince1970: 123))
    }

    func testMalformedMissingNullAndWrongTypeDataStayEncapsulated() {
        for json in ["not JSON", "{}", #"{"name":null}"#, #"{"name":42}"#] {
            XCTAssertThrowsError(try DataParserImpl().parse(Data(json.utf8), as: Record.self)) {
                XCTAssertEqual($0 as? DataParserError, .invalidData)
            }
        }
    }

    func testCustomDecodingErrorStaysEncapsulated() {
        XCTAssertThrowsError(try DataParserImpl().parse(Data("{}".utf8), as: FailingRecord.self)) {
            XCTAssertEqual($0 as? DataParserError, .invalidData)
        }
    }

    #if DEBUG

    func testDebugDiagnosticsIdentifyPathAndExpectedTypeWithoutRawDetails() {
        let context = DecodingError.Context(
            codingPath: [Key(index: 2), Key("name")],
            debugDescription: "secret payload",
            underlyingError: PrivateDecodeError()
        )
        let diagnostic = DataParserImpl.diagnostic(
            for: DecodingError.typeMismatch(String.self, context),
            decoding: [Record].self
        )
        XCTAssertTrue(diagnostic.contains("$[2].name"))
        XCTAssertTrue(diagnostic.contains("expected String"))
        XCTAssertFalse(diagnostic.contains("secret payload"))
        XCTAssertFalse(diagnostic.contains("PrivateDecodeError"))
    }

    func testDebugDiagnosticsDistinguishMissingNullAndCorruptFields() {
        let context = DecodingError.Context(codingPath: [], debugDescription: "private")
        XCTAssertTrue(
            DataParserImpl.diagnostic(
                for: DecodingError.keyNotFound(Key("name"), context),
                decoding: Record.self
            )
            .contains("missing key at $.name")
        )
        XCTAssertTrue(
            DataParserImpl.diagnostic(
                for: DecodingError.valueNotFound(String.self, context),
                decoding: Record.self
            )
            .contains("missing/null String")
        )
        XCTAssertTrue(
            DataParserImpl.diagnostic(
                for: DecodingError.dataCorrupted(context),
                decoding: Record.self
            )
            .contains("malformed JSON")
        )
        XCTAssertTrue(
            DataParserImpl.diagnostic(
                for: PrivateDecodeError(),
                decoding: Record.self
            )
            .contains("custom decoding failed")
        )
    }
    #endif
}

private struct Key: CodingKey {
    let stringValue: String
    let intValue: Int?

    init(_ value: String) {
        stringValue = value
        intValue = nil
    }

    init(index: Int) {
        stringValue = "Index \(index)"
        intValue = index
    }

    init?(stringValue: String) { self.init(stringValue) }

    init?(intValue: Int) { self.init(index: intValue) }
}

private struct PrivateDecodeError: Error {}
private struct FailingRecord: Decodable {

    init(from decoder: Decoder) throws { throw PrivateDecodeError() }
}
