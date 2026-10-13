import Foundation

/// Decodes response data while exposing only typed parsing failures.
protocol DataParserProtocol {

    func parse<Value: Decodable>(_ data: Data, as type: Value.Type) throws(DataParserError) -> Value
}
