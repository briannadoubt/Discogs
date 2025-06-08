import Testing
@testable import Discogs

@Suite("Networking Tests")
struct NetworkingTests {
    
    @Test("HTTPMethod enum has correct raw values")
    func testHTTPMethodRawValues() {
        #expect(HTTPMethod.get.rawValue == "GET")
        #expect(HTTPMethod.post.rawValue == "POST")
        #expect(HTTPMethod.put.rawValue == "PUT")
        #expect(HTTPMethod.delete.rawValue == "DELETE")
        #expect(HTTPMethod.patch.rawValue == "PATCH")
    }
    
    @Test("HTTPMethod conforms to Sendable")
    func testHTTPMethodSendableConformance() {
        let method = HTTPMethod.get
        
        // When/Then - This test passes if the code compiles
        Task {
            let _ = method
        }
    }
    
    @Test("All HTTP methods are case-accessible")
    func testHTTPMethodCases() {
        let methods: [HTTPMethod] = [.get, .post, .put, .delete, .patch]
        
        #expect(methods.count == 5)
        #expect(methods.contains(.get))
        #expect(methods.contains(.post))
        #expect(methods.contains(.put))
        #expect(methods.contains(.delete))
        #expect(methods.contains(.patch))
    }
    
    @Test("HTTPMethod can be initialized from raw value")
    func testHTTPMethodFromRawValue() {
        #expect(HTTPMethod(rawValue: "GET") == .get)
        #expect(HTTPMethod(rawValue: "POST") == .post)
        #expect(HTTPMethod(rawValue: "PUT") == .put)
        #expect(HTTPMethod(rawValue: "DELETE") == .delete)
        #expect(HTTPMethod(rawValue: "PATCH") == .patch)
        #expect(HTTPMethod(rawValue: "INVALID") == nil)
    }
}
