/// SMPError – domain errors surfaced across the entire framework.
public enum SMPError: Error, Sendable {
    case networkError(String)
    case decodingError(String)
    case unauthorized
    case unknown(String)
}
