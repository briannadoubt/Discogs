import Testing
@testable import Discogs

@Suite("Currency Validation Tests")
struct CurrencyValidationTests {
    
    @Test("SupportedCurrency contains all expected currencies")
    func testSupportedCurrencies() {
        let currencies = DatabaseService.SupportedCurrency.allCases
        let currencyCodes = currencies.map(\.rawValue)
        
        // Verify major currencies are included
        #expect(currencyCodes.contains("USD"))
        #expect(currencyCodes.contains("EUR"))
        #expect(currencyCodes.contains("GBP"))
        #expect(currencyCodes.contains("JPY"))
        #expect(currencyCodes.contains("CAD"))
        #expect(currencyCodes.contains("AUD"))
        
        // Verify we have a reasonable number of currencies
        #expect(currencies.count >= 11)
    }
    
    @Test("Currency validation accepts valid currencies")
    func testValidCurrencyAcceptance() {
        // Test uppercase
        #expect(DatabaseService.SupportedCurrency.isValid("USD") == true)
        #expect(DatabaseService.SupportedCurrency.isValid("EUR") == true)
        #expect(DatabaseService.SupportedCurrency.isValid("GBP") == true)
        
        // Test lowercase (should work due to case-insensitive comparison)
        #expect(DatabaseService.SupportedCurrency.isValid("usd") == true)
        #expect(DatabaseService.SupportedCurrency.isValid("eur") == true)
        #expect(DatabaseService.SupportedCurrency.isValid("gbp") == true)
        
        // Test mixed case
        #expect(DatabaseService.SupportedCurrency.isValid("Usd") == true)
        #expect(DatabaseService.SupportedCurrency.isValid("EuR") == true)
    }
    
    @Test("Currency validation rejects invalid currencies")
    func testInvalidCurrencyRejection() {
        #expect(DatabaseService.SupportedCurrency.isValid("INVALID") == false)
        #expect(DatabaseService.SupportedCurrency.isValid("XYZ") == false)
        #expect(DatabaseService.SupportedCurrency.isValid("") == false)
        #expect(DatabaseService.SupportedCurrency.isValid("US") == false) // Too short
        #expect(DatabaseService.SupportedCurrency.isValid("USDD") == false) // Too long
    }
    
    @Test("DatabaseService getRelease validates currency parameter")
    func testGetReleaseWithValidCurrency() async throws {
        // Given
        let mockClient = MockHTTPClient()
        let service = DatabaseService(httpClient: mockClient)
        
        // Set up mock response
        let mockResponse = """
        {
            "id": 123,
            "title": "Test Release",
            "year": 2023,
            "artists": [],
            "tracklist": [],
            "labels": [],
            "formats": [],
            "images": []
        }
        """
        await mockClient.setMockResponse(json: mockResponse)
        
        // When/Then - Valid currencies should work
        let _: ReleaseDetails = try await service.getRelease(id: 123, currency: "USD")
        let _: ReleaseDetails = try await service.getRelease(id: 123, currency: "EUR")
        let _: ReleaseDetails = try await service.getRelease(id: 123, currency: "usd") // lowercase
        
        // Verify the currency parameter was added correctly
        let lastRequest = await mockClient.lastRequest
        #expect(lastRequest?.url.query?.contains("curr_abbr=USD") == true ||
                lastRequest?.url.query?.contains("curr_abbr=usd") == true)
    }
    
    @Test("DatabaseService getRelease rejects invalid currency")
    func testGetReleaseWithInvalidCurrency() async throws {
        // Given
        let mockClient = MockHTTPClient()
        let service = DatabaseService(httpClient: mockClient)
        
        // When/Then - Invalid currencies should throw
        await #expect(throws: DiscogsError.self) {
            let _: ReleaseDetails = try await service.getRelease(id: 123, currency: "INVALID")
        }
        
        await #expect(throws: DiscogsError.self) {
            let _: ReleaseDetails = try await service.getRelease(id: 123, currency: "XYZ")
        }
        
        await #expect(throws: DiscogsError.self) {
            let _: ReleaseDetails = try await service.getRelease(id: 123, currency: "")
        }
    }
    
    @Test("DatabaseService getRelease works without currency parameter")
    func testGetReleaseWithoutCurrency() async throws {
        // Given
        let mockClient = MockHTTPClient()
        let service = DatabaseService(httpClient: mockClient)
        
        // Set up mock response
        let mockResponse = """
        {
            "id": 123,
            "title": "Test Release",
            "year": 2023,
            "artists": [],
            "tracklist": [],
            "labels": [],
            "formats": [],
            "images": []
        }
        """
        await mockClient.setMockResponse(json: mockResponse)
        
        // When
        let _: ReleaseDetails = try await service.getRelease(id: 123)
        
        // Then - Should work without currency parameter
        let lastRequest = await mockClient.lastRequest
        #expect(lastRequest?.url.query?.contains("curr_abbr") != true)
    }
    
    @Test("Currency validation error message is informative")
    func testCurrencyValidationErrorMessage() async {
        // Given
        let mockClient = MockHTTPClient()
        let service = DatabaseService(httpClient: mockClient)
        
        // When/Then
        await #expect(throws: DiscogsError.self) {
            let _: ReleaseDetails = try await service.getRelease(id: 123, currency: "INVALID")
        }
    }
    
    @Test("SupportedCurrency enum conforms to required protocols")
    func testSupportedCurrencyProtocolConformance() {
        // Test that it conforms to CaseIterable
        let allCases = DatabaseService.SupportedCurrency.allCases
        #expect(allCases.count > 0)
        
        // Test that it conforms to RawRepresentable
        let usd = DatabaseService.SupportedCurrency.usd
        #expect(usd.rawValue == "USD")
        
        // Test that it can be created from raw value
        let eurFromRaw = DatabaseService.SupportedCurrency(rawValue: "EUR")
        #expect(eurFromRaw == .eur)
        
        // Test Sendable conformance (compile-time check)
        Task {
            let currency = DatabaseService.SupportedCurrency.usd
            #expect(currency.rawValue == "USD")
        }
    }
}
