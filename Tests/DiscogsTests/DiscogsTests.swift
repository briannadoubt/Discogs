import Testing
@testable import Discogs

// Define test case class
@Suite("Basic Discogs Tests")
struct BasicDiscogsTests {
    @Test("Discogs can be imported")
    func testImport() {
        // This test just ensures the module can be imported
        #expect(true)
    }
}
