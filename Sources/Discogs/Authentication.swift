import Foundation
#if canImport(CryptoKit)
import CryptoKit
#endif
#if canImport(CommonCrypto)
import CommonCrypto
#endif

/// Authentication methods supported by the Discogs API
public enum AuthMethod: Sendable {
    /// Personal access token authentication
    /// 
    /// Use this method for simple authentication with a personal access token.
    /// You can obtain a personal access token from your Discogs developer settings.
    case token(String)
    
    /// OAuth 1.0a authentication
    /// 
    /// Use this method for OAuth-based authentication when building applications
    /// that need to act on behalf of other users.
    /// - Parameters:
    ///   - consumerKey: Your application's consumer key
    ///   - consumerSecret: Your application's consumer secret
    ///   - accessToken: The user's OAuth access token
    ///   - accessTokenSecret: The user's OAuth access token secret
    case oauth(consumerKey: String, consumerSecret: String, accessToken: String, accessTokenSecret: String)
}

/// Authentication class for OAuth and token-based authentication with Discogs API
/// 
/// This class provides utilities for OAuth 1.0a authentication flow including
/// requesting tokens, generating authorization URLs, and exchanging verifiers for access tokens.
public class Authentication {
    /// The HTTP client used for making authentication requests
    private let client: HTTPClientProtocol
    
    /// Initialize with an HTTP client
    /// - Parameter client: The HTTP client to use for authentication requests
    public init(client: HTTPClientProtocol) {
        self.client = client
    }
    
    /// Generate OAuth request token
    /// 
    /// This is the first step in the OAuth 1.0a flow. Use the returned token
    /// to generate an authorization URL for the user.
    /// - Parameters:
    ///   - consumerKey: Your application's consumer key
    ///   - consumerSecret: Your application's consumer secret
    ///   - callbackURL: The URL to redirect to after authorization
    /// - Returns: An OAuth token containing the request token and secret
    /// - Throws: `DiscogsError` if the request fails
    public func getRequestToken(
        consumerKey: String,
        consumerSecret: String,
        callbackURL: String
    ) async throws -> OAuthToken {
        let endpoint = "/oauth/request_token"
        let parameters = [
            "oauth_consumer_key": consumerKey,
            "oauth_callback": callbackURL,
            "oauth_signature_method": "HMAC-SHA1",
            "oauth_timestamp": String(generateTimestamp()),
            "oauth_nonce": generateNonce(),
            "oauth_version": "1.0"
        ]
        
        let signature = generateOAuthSignature(
            httpMethod: "GET",
            baseURL: client.baseURL.absoluteString + endpoint,
            parameters: parameters,
            consumerSecret: consumerSecret,
            tokenSecret: nil
        )
        
        var allParams = parameters
        allParams["oauth_signature"] = signature
        
        // Create OAuth authorization header
        let authHeader = "OAuth " + allParams
            .sorted { $0.key < $1.key }
            .map { "\(encodeURIComponent($0.key))=\"\(encodeURIComponent($0.value))\"" }
            .joined(separator: ", ")
        
        let response: String = try await client.performRequest(
            endpoint: endpoint,
            method: .get,
            parameters: [:], // Parameters go in the auth header for OAuth
            body: nil,
            headers: ["Authorization": authHeader]
        )
        
        return try parseOAuthToken(from: response)
    }
    
    /// Generate OAuth authorization URL
    /// 
    /// After obtaining a request token, use this method to generate the URL
    /// where the user should be redirected to authorize the application.
    /// - Parameter requestToken: The request token obtained from `getRequestToken`
    /// - Returns: The authorization URL as a string
    public func getAuthorizationURL(requestToken: String) -> String {
        return "https://discogs.com/oauth/authorize?oauth_token=\(requestToken)"
    }
    
    /// Exchange OAuth verifier for access token
    /// 
    /// This is the final step in the OAuth 1.0a flow. After the user authorizes
    /// the application, Discogs redirects to the callback URL with a verifier code.
    /// Use this method to exchange the verifier for an access token.
    /// - Parameters:
    ///   - consumerKey: Your application's consumer key
    ///   - consumerSecret: Your application's consumer secret
    ///   - requestToken: The request token obtained from `getRequestToken`
    ///   - requestTokenSecret: The request token secret obtained from `getRequestToken`
    ///   - verifier: The verifier code received from Discogs
    /// - Returns: An OAuth token containing the access token and secret
    /// - Throws: `DiscogsError` if the request fails
    public func getAccessToken(
        consumerKey: String,
        consumerSecret: String,
        requestToken: String,
        requestTokenSecret: String,
        verifier: String
    ) async throws -> OAuthToken {
        let endpoint = "/oauth/access_token"
        let parameters = [
            "oauth_consumer_key": consumerKey,
            "oauth_token": requestToken,
            "oauth_verifier": verifier,
            "oauth_signature_method": "HMAC-SHA1",
            "oauth_timestamp": String(generateTimestamp()),
            "oauth_nonce": generateNonce(),
            "oauth_version": "1.0"
        ]
        
        let signature = generateOAuthSignature(
            httpMethod: "POST",
            baseURL: client.baseURL.absoluteString + endpoint,
            parameters: parameters,
            consumerSecret: consumerSecret,
            tokenSecret: requestTokenSecret
        )
        
        var allParams = parameters
        allParams["oauth_signature"] = signature
        
        // Create OAuth authorization header
        let authHeader = "OAuth " + allParams
            .sorted { $0.key < $1.key }
            .map { "\(encodeURIComponent($0.key))=\"\(encodeURIComponent($0.value))\"" }
            .joined(separator: ", ")
        
        let response: String = try await client.performRequest(
            endpoint: endpoint,
            method: .post,
            parameters: [:],
            body: nil,
            headers: ["Authorization": authHeader]
        )
        
        return try parseOAuthToken(from: response)
    }
    
    /// Validate personal access token
    /// 
    /// Use this method to check if a personal access token is valid.
    /// - Parameter token: The personal access token to validate
    /// - Returns: `true` if the token is valid, `false` otherwise
    /// - Throws: `DiscogsError` if the request fails
    public func validateToken(_ token: String) async throws -> Bool {
        let endpoint = "/oauth/identity"
        
        do {
            let _: UserIdentity = try await client.performRequest(
                endpoint: endpoint,
                method: .get,
                parameters: [:],
                body: nil,
                headers: ["Authorization": "Discogs token=\(token)"]
            )
            return true
        } catch {
            return false
        }
    }
    
    /// Generate OAuth signature for HMAC-SHA1
    /// 
    /// This method generates a signature for OAuth 1.0a using the HMAC-SHA1
    /// algorithm. The signature is used to verify the authenticity of the
    /// request and to protect against tampering.
    /// - Parameters:
    ///   - httpMethod: The HTTP method of the request (e.g., "GET", "POST")
    ///   - baseURL: The base URL of the request
    ///   - parameters: The OAuth parameters
    ///   - consumerSecret: Your application's consumer secret
    ///   - tokenSecret: The token secret (optional, use `nil` for request token)
    /// - Returns: The base64-encoded HMAC-SHA1 signature
    public func generateOAuthSignature(
        httpMethod: String,
        baseURL: String,
        parameters: [String: String],
        consumerSecret: String,
        tokenSecret: String?
    ) -> String {
        let parameterString = encodeOAuthParameters(parameters)
        let signatureBaseString = "\(httpMethod.uppercased())&\(encodeURIComponent(baseURL))&\(encodeURIComponent(parameterString))"
        
        let signingKey = "\(encodeURIComponent(consumerSecret))&\(encodeURIComponent(tokenSecret ?? ""))"
        
        return hmacSHA1(data: signatureBaseString, key: signingKey)
    }
    
    /// Encode OAuth parameters into query string format
    /// 
    /// This method encodes the OAuth parameters into a query string format
    /// suitable for inclusion in the signature base string. Parameters are
    /// sorted alphabetically by key and URL-encoded.
    /// - Parameter parameters: The OAuth parameters to encode
    /// - Returns: The encoded query string
    public func encodeOAuthParameters(_ parameters: [String: String]) -> String {
        return parameters
            .sorted { $0.key < $1.key }
            .map { "\(encodeURIComponent($0.key))=\(encodeURIComponent($0.value))" }
            .joined(separator: "&")
    }
    
    /// Generate timestamp for OAuth
    /// 
    /// This method generates a timestamp for OAuth 1.0a requests. The timestamp
    /// is the number of seconds since the Unix epoch (January 1, 1970).
    /// - Returns: The current timestamp as an integer
    public func generateTimestamp() -> Int {
        return Int(Date().timeIntervalSince1970)
    }
    
    /// Generate nonce for OAuth
    /// 
    /// This method generates a nonce (number used once) for OAuth 1.0a requests.
    /// The nonce is a random string that helps to prevent replay attacks.
    /// - Returns: A random nonce string
    public func generateNonce() -> String {
        return UUID().uuidString.replacingOccurrences(of: "-", with: "")
    }
    
    /// Refresh OAuth token
    /// 
    /// Use this method to refresh an expired OAuth token using the refresh token.
    /// - Parameter refreshToken: The refresh token obtained during the initial
    ///   authorization flow
    /// - Returns: An OAuth token containing the new access token and secret
    /// - Throws: `DiscogsError` if the request fails
    public func refreshToken(_ refreshToken: String) async throws -> OAuthToken {
        let endpoint = "/oauth/token"
        let body = [
            "grant_type": "refresh_token",
            "refresh_token": refreshToken
        ]
        
        let response: OAuth2Token = try await client.performRequest(
            endpoint: endpoint,
            method: .post,
            parameters: [:],
            body: body,
            headers: nil
        )
        
        // Convert OAuth2Token to OAuthToken format for consistency
        return OAuthToken(
            token: response.accessToken,
            tokenSecret: response.refreshToken ?? ""
        )
    }
    
    /// Create authentication headers
    /// 
    /// This method creates the necessary headers for authenticating requests
    /// to the Discogs API using a personal access token.
    /// - Parameters:
    ///   - token: The personal access token
    ///   - userAgent: The user agent string for the request
    /// - Returns: A dictionary containing the "Authorization" and "User-Agent" headers
    public func createAuthenticationHeaders(token: String, userAgent: String) -> [String: String] {
        return [
            "Authorization": "Discogs token=\(token)",
            "User-Agent": userAgent
        ]
    }
    
    /// Validate callback URL
    /// 
    /// Use this method to validate the callback URL provided during the OAuth
    /// authorization flow. The URL must be non-empty and have a valid scheme
    /// (http, https, or a custom URL scheme).
    /// - Parameter urlString: The callback URL as a string
    /// - Returns: `true` if the URL is valid, `false` otherwise
    public func isValidCallbackURL(_ urlString: String) -> Bool {
        guard !urlString.isEmpty,
              let url = URL(string: urlString),
              let scheme = url.scheme else {
            return false
        }
        
        // Accept http, https, and custom URL schemes, but reject ftp
        return ["http", "https"].contains(scheme.lowercased()) || (!["ftp"].contains(scheme.lowercased()) && !scheme.isEmpty)
    }
    
    // MARK: - Private Helper Methods
    
    /// Parse OAuth token from response string
    /// - Parameter response: The URL-encoded response string from the OAuth endpoint
    /// - Returns: An `OAuthToken` containing the token and secret
    /// - Throws: `NSError` if the response format is invalid
    private func parseOAuthToken(from response: String) throws -> OAuthToken {
        let components = response.components(separatedBy: "&")
        var token: String?
        var tokenSecret: String?
        
        for component in components {
            let keyValue = component.components(separatedBy: "=")
            guard keyValue.count == 2 else { continue }
            
            let key = keyValue[0]
            let value = keyValue[1]
            
            switch key {
            case "oauth_token":
                token = value
            case "oauth_token_secret":
                tokenSecret = value
            default:
                break
            }
        }
        
        guard let token = token, let tokenSecret = tokenSecret else {
            throw NSError(domain: "OAuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid OAuth response"])
        }
        
        return OAuthToken(token: token, tokenSecret: tokenSecret)
    }
    
    /// Public method to encode URI components for OAuth signatures
    /// 
    /// This method encodes strings according to RFC 3986 for use in OAuth signatures.
    /// All characters except unreserved characters (A-Z, a-z, 0-9, -, ., _, ~, /) 
    /// are percent-encoded.
    /// - Parameter string: The string to encode
    /// - Returns: The percent-encoded string
    public func encodeURIComponent(_ string: String) -> String {
        return string.addingPercentEncoding(withAllowedCharacters: .unreservedRFC3986) ?? string
    }
    
    /// Generate HMAC-SHA1 signature
    /// 
    /// Creates an HMAC-SHA1 signature using the provided data and key.
    /// The signature is base64-encoded and padding characters are removed.
    /// - Parameters:
    ///   - data: The data to sign
    ///   - key: The signing key
    /// - Returns: The base64-encoded signature without padding
    private func hmacSHA1(data: String, key: String) -> String {
        #if canImport(CryptoKit)
        // Use CryptoKit on platforms where it's available (iOS 13+, macOS 10.15+, etc.)
        let keyData = SymmetricKey(data: key.data(using: .utf8)!)
        let dataData = data.data(using: .utf8)!
        
        let signature = HMAC<Insecure.SHA1>.authenticationCode(for: dataData, using: keyData)
        return Data(signature).base64EncodedString().trimmingCharacters(in: CharacterSet(charactersIn: "="))
        #elseif canImport(CommonCrypto)
        // Use CommonCrypto on older Apple platforms
        let keyData = key.data(using: .utf8)!
        let dataData = data.data(using: .utf8)!
        
        var result = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
        CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA1), keyData.withUnsafeBytes { $0.baseAddress }, keyData.count, dataData.withUnsafeBytes { $0.baseAddress }, dataData.count, &result)
        
        let hmacData = Data(result)
        return hmacData.base64EncodedString().trimmingCharacters(in: CharacterSet(charactersIn: "="))
        #else
        // Fallback implementation for Linux and other platforms
        return linuxHmacSHA1(data: data, key: key)
        #endif
    }
    
    #if !canImport(CryptoKit) && !canImport(CommonCrypto)
    /// Linux-compatible HMAC-SHA1 implementation
    /// This provides a pure Swift implementation of HMAC-SHA1 for platforms
    /// where neither CryptoKit nor CommonCrypto are available.
    private func linuxHmacSHA1(data: String, key: String) -> String {
        let keyData = Array(key.utf8)
        let dataData = Array(data.utf8)
        
        // HMAC-SHA1 implementation
        var keyBytes = keyData
        let blockSize = 64  // SHA-1 block size
        
        // If key is longer than block size, hash it
        if keyBytes.count > blockSize {
            keyBytes = Array(sha1(keyBytes))
        }
        
        // Pad key to block size
        while keyBytes.count < blockSize {
            keyBytes.append(0)
        }
        
        // Create inner and outer padding
        let innerPad = keyBytes.map { $0 ^ 0x36 }
        let outerPad = keyBytes.map { $0 ^ 0x5c }
        
        // HMAC = SHA1(outerPad + SHA1(innerPad + data))
        let innerHash = sha1(innerPad + dataData)
        let finalHash = sha1(outerPad + Array(innerHash))
        
        return Data(finalHash).base64EncodedString().trimmingCharacters(in: CharacterSet(charactersIn: "="))
    }
    
    /// Pure Swift SHA-1 implementation for Linux compatibility
    private func sha1(_ data: [UInt8]) -> [UInt8] {
        var message = data
        let originalLength = UInt64(message.count * 8)
        
        // Pre-processing: adding padding bits
        message.append(0x80)
        while (message.count % 64) != 56 {
            message.append(0)
        }
        
        // Append original length as 64-bit big-endian
        for i in stride(from: 56, through: 0, by: -8) {
            message.append(UInt8((originalLength >> i) & 0xFF))
        }
        
        // Initialize hash values
        var h0: UInt32 = 0x67452301
        var h1: UInt32 = 0xEFCDAB89
        var h2: UInt32 = 0x98BADCFE
        var h3: UInt32 = 0x10325476
        var h4: UInt32 = 0xC3D2E1F0
        
        // Process message in 512-bit chunks
        for chunkStart in stride(from: 0, to: message.count, by: 64) {
            var w = [UInt32](repeating: 0, count: 80)
            
            // Break chunk into sixteen 32-bit big-endian words
            for i in 0..<16 {
                let offset = chunkStart + i * 4
                w[i] = (UInt32(message[offset]) << 24) |
                       (UInt32(message[offset + 1]) << 16) |
                       (UInt32(message[offset + 2]) << 8) |
                       UInt32(message[offset + 3])
            }
            
            // Extend the sixteen 32-bit words into eighty 32-bit words
            for i in 16..<80 {
                let temp = w[i-3] ^ w[i-8] ^ w[i-14] ^ w[i-16]
                w[i] = rotateLeft(temp, by: 1)
            }
            
            // Initialize hash value for this chunk
            var a = h0, b = h1, c = h2, d = h3, e = h4
            
            // Main loop
            for i in 0..<80 {
                let f: UInt32
                let k: UInt32
                
                switch i {
                case 0..<20:
                    f = (b & c) | ((~b) & d)
                    k = 0x5A827999
                case 20..<40:
                    f = b ^ c ^ d
                    k = 0x6ED9EBA1
                case 40..<60:
                    f = (b & c) | (b & d) | (c & d)
                    k = 0x8F1BBCDC
                default:
                    f = b ^ c ^ d
                    k = 0xCA62C1D6
                }
                
                let temp = rotateLeft(a, by: 5) &+ f &+ e &+ k &+ w[i]
                e = d
                d = c
                c = rotateLeft(b, by: 30)
                b = a
                a = temp
            }
            
            // Add this chunk's hash to result so far
            h0 = h0 &+ a
            h1 = h1 &+ b
            h2 = h2 &+ c
            h3 = h3 &+ d
            h4 = h4 &+ e
        }
        
        // Produce the final hash value as a 160-bit number (20 bytes)
        var result = [UInt8]()
        for h in [h0, h1, h2, h3, h4] {
            result.append(UInt8((h >> 24) & 0xFF))
            result.append(UInt8((h >> 16) & 0xFF))
            result.append(UInt8((h >> 8) & 0xFF))
            result.append(UInt8(h & 0xFF))
        }
        
        return result
    }
    
    /// Left rotate a 32-bit integer
    private func rotateLeft(_ value: UInt32, by amount: UInt32) -> UInt32 {
        return (value << amount) | (value >> (32 - amount))
    }
    #endif
}

/// Character set for RFC 3986 unreserved characters
/// 
/// Contains characters that do not need to be percent-encoded in OAuth signatures:
/// A-Z, a-z, 0-9, hyphen, period, underscore, tilde, and forward slash.
extension CharacterSet {
    static let unreservedRFC3986 = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~/")
}

/// OAuth token response from Discogs API
/// 
/// Contains the OAuth token and token secret returned by the Discogs OAuth endpoints.
/// This is used for both request tokens and access tokens in the OAuth 1.0a flow.
public struct OAuthToken: Codable, Sendable {
    /// The OAuth token
    public let token: String
    
    /// The OAuth token secret
    public let tokenSecret: String
    
    enum CodingKeys: String, CodingKey {
        case token = "oauth_token"
        case tokenSecret = "oauth_token_secret"
    }
}

/// OAuth 2.0 token response (JSON format)
/// 
/// Contains the OAuth 2.0 token information returned by modern OAuth endpoints.
/// This structure supports refresh tokens and token expiration.
public struct OAuth2Token: Codable, Sendable {
    /// The access token for API requests
    public let accessToken: String
    
    /// The type of token (usually "Bearer")
    public let tokenType: String
    
    /// Token expiration time in seconds (optional)
    public let expiresIn: Int?
    
    /// Refresh token for obtaining new access tokens (optional)
    public let refreshToken: String?
    
    /// The scope of access granted by the token (optional)
    public let scope: String?
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
        case refreshToken = "refresh_token"
        case scope
    }
}
