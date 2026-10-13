import Foundation

/// Creates a decoder per operation; no mutable decoder is shared between requests.
struct DataParserImpl: DataParserProtocol {
    private let dateDecodingStrategy: JSONDecoder.DateDecodingStrategy

    init(dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .iso8601) {
        self.dateDecodingStrategy = dateDecodingStrategy
    }

    func parse<Value: Decodable>(_ data: Data, as type: Value.Type) throws(DataParserError) -> Value
    {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = dateDecodingStrategy
        do {
            return try decoder.decode(type, from: data)
        } catch {
            #if DEBUG
            print(Self.diagnostic(for: error, decoding: type))
            #endif
            throw .invalidData
        }
    }

    #if DEBUG
    /// Structural diagnostics only: do not print payloads, raw error descriptions,
    /// underlying errors, request URLs, or credentials.

    static func diagnostic<Value>(for error: Error, decoding type: Value.Type) -> String {
        let prefix = "[DataParser] Could not decode \(String(describing: type))"
        switch error {
        case DecodingError.keyNotFound(let key, let context):
            return "\(prefix): missing key at \(path(context.codingPath + [key]))."
        case DecodingError.typeMismatch(let expected, let context):
            return
                "\(prefix): expected \(String(describing: expected)) at \(path(context.codingPath))."
        case DecodingError.valueNotFound(let expected, let context):
            return
                "\(prefix): missing/null \(String(describing: expected)) at \(path(context.codingPath))."
        case DecodingError.dataCorrupted(let context):
            return
                "\(prefix): malformed JSON or invalid encoded value at \(path(context.codingPath))."
        default:
            return "\(prefix): custom decoding failed."
        }
    }

    private static func path(_ codingPath: [any CodingKey]) -> String {
        codingPath.reduce("$") { result, key in
            if let index = key.intValue { return "\(result)[\(index)]" }
            return "\(result).\(key.stringValue)"
        }
    }
    #endif
}
