import Foundation

public struct MarketplaceService: DiscogsServiceProtocol { // Changed to struct, added Sendable
    
    // MARK: - Properties
    
    /// The HTTP client used for making requests
    public let httpClient: HTTPClientProtocol
    
    // MARK: - Initialization
    
    /// Initialize with an HTTP client
    /// - Parameter httpClient: The HTTP client to use for API requests
    public init(httpClient: HTTPClientProtocol) {
        self.httpClient = httpClient
    }
    
    /// Convenience initializer with Discogs client (for backward compatibility)
    /// - Parameter client: The Discogs client to use for API requests
    public init(client: Discogs) {
        self.httpClient = client
    }
    
    // MARK: - Inventory Methods
    
    /// Get a user's marketplace inventory
    /// - Parameters:
    ///   - username: The username
    ///   - status: Filter by listing status (optional)
    ///   - sort: Sort field
    ///   - sortOrder: Sort direction
    ///   - page: Page number (default: 1)
    ///   - perPage: Items per page (default: 50)
    /// - Returns: A `PaginatedResponse` containing `Listing` objects.
    /// - Throws: A `DiscogsError` if the request fails.
    public func getInventory(
        username: String,
        status: ListingStatus? = nil,
        sort: InventorySort = .listed,
        sortOrder: SortOrder = .descending,
        page: Int = 1,
        perPage: Int = 50
    ) async throws -> PaginatedResponse<Listing> {
        var parameters = [
            "page": String(page),
            "per_page": String(perPage),
            "sort": sort.rawValue,
            "sort_order": sortOrder.rawValue
        ]
        
        if let status = status {
            parameters["status"] = status.rawValue
        }
        
        return try await performRequest(
            endpoint: "users/\(username)/inventory",
            parameters: parameters
        )
    }
    
    /// Get the listing for a specific item
    /// - Parameters:
    ///   - listingId: The listing ID
    /// - Returns: A `Listing` object.
    /// - Throws: A `DiscogsError` if the request fails.
    public func getListing(listingId: Int) async throws -> Listing {
        try await performRequest(
            endpoint: "marketplace/listings/\(listingId)"
        )
    }
    
    /// Create a new marketplace listing
    /// - Parameters:
    ///   - releaseId: The ID of the release being listed
    ///   - condition: The condition of the item
    ///   - sleeveCondition: The condition of the sleeve
    ///   - price: The price as a decimal string
    ///   - comments: Description or comments about the item
    ///   - allowOffers: Whether to allow offers from buyers
    ///   - status: The status of the listing
    ///   - externalId: Your own identifier for the item
    ///   - location: The physical location of the item
    ///   - weight: The weight of the item in grams
    ///   - formatQuantity: The number of items in this format
    /// - Returns: A `Listing` object.
    /// - Throws: A `DiscogsError` if the request fails.
    public func createListing(
        releaseId: Int,
        condition: ItemCondition,
        sleeveCondition: ItemCondition? = nil,
        price: String,
        comments: String? = nil,
        allowOffers: Bool = true,
        status: ListingStatus = .draft,
        externalId: String? = nil,
        location: String? = nil,
        weight: Int? = nil,
        formatQuantity: Int = 1
    ) async throws -> Listing {
        var body: [String: any Sendable] = [
            "release_id": releaseId,
            "condition": condition.rawValue,
            "price": price,
            "status": status.rawValue,
            "allow_offers": allowOffers,
            "format_quantity": formatQuantity
        ]
        
        if let sleeveCondition = sleeveCondition {
            body["sleeve_condition"] = sleeveCondition.rawValue
        }
        
        if let comments = comments {
            body["comments"] = comments
        }
        
        if let externalId = externalId {
            body["external_id"] = externalId
        }
        
        if let location = location {
            body["location"] = location
        }
        
        if let weight = weight {
            body["weight"] = weight
        }
        
        return try await performRequest(
            endpoint: "marketplace/listings",
            method: .post,
            body: body
        )
    }
    
    /// Edit a marketplace listing
    /// - Parameters:
    ///   - listingId: The ID of the listing to edit
    ///   - releaseId: The ID of the release being listed
    ///   - condition: The condition of the item
    ///   - sleeveCondition: The condition of the sleeve
    ///   - price: The price as a decimal string
    ///   - comments: Description or comments about the item
    ///   - allowOffers: Whether to allow offers from buyers
    ///   - status: The status of the listing
    ///   - externalId: Your own identifier for the item
    ///   - location: The physical location of the item
    ///   - weight: The weight of the item in grams
    ///   - formatQuantity: The number of items in this format
    /// - Returns: A `Listing` object.
    /// - Throws: A `DiscogsError` if the request fails.
    public func editListing(
        listingId: Int,
        releaseId: Int? = nil,
        condition: ItemCondition? = nil,
        sleeveCondition: ItemCondition? = nil,
        price: String? = nil,
        comments: String? = nil,
        allowOffers: Bool? = nil,
        status: ListingStatus? = nil,
        externalId: String? = nil,
        location: String? = nil,
        weight: Int? = nil,
        formatQuantity: Int? = nil
    ) async throws -> Listing {
        var body: [String: any Sendable] = [:]
        
        if let releaseId = releaseId { body["release_id"] = releaseId }
        if let condition = condition { body["condition"] = condition.rawValue }
        if let sleeveCondition = sleeveCondition { body["sleeve_condition"] = sleeveCondition.rawValue }
        if let price = price { body["price"] = price }
        if let comments = comments { body["comments"] = comments }
        if let allowOffers = allowOffers { body["allow_offers"] = allowOffers }
        if let status = status { body["status"] = status.rawValue }
        if let externalId = externalId { body["external_id"] = externalId }
        if let location = location { body["location"] = location }
        if let weight = weight { body["weight"] = weight }
        if let formatQuantity = formatQuantity { body["format_quantity"] = formatQuantity }
        
        return try await performRequest(
            endpoint: "marketplace/listings/\(listingId)",
            method: .post,
            body: body
        )
    }
    
    /// Delete a marketplace listing
    /// - Parameters:
    ///   - listingId: The ID of the listing to delete
    /// - Returns: A `SuccessResponse` object.
    /// - Throws: A `DiscogsError` if the request fails.
    public func deleteListing(listingId: Int) async throws -> SuccessResponse {
        try await performRequest(
            endpoint: "marketplace/listings/\(listingId)",
            method: .delete
        )
    }
    
    // MARK: - Orders
    
    /// Get a list of the user's orders
    /// - Parameters:
    ///   - status: Filter by order status (optional)
    ///   - sort: Sort field (optional)
    ///   - sortOrder: Sort direction (optional)
    ///   - page: Page number (default: 1)
    ///   - perPage: Items per page (default: 50)
    /// - Returns: A `PaginatedResponse` containing `Order` objects.
    /// - Throws: A `DiscogsError` if the request fails.
    public func getOrders(
        status: OrderStatus? = nil,
        sort: OrderSort? = nil,
        sortOrder: SortOrder? = nil,
        page: Int = 1,
        perPage: Int = 50
    ) async throws -> PaginatedResponse<Order> {
        var parameters = [
            "page": String(page),
            "per_page": String(perPage)
        ]
        
        if let status = status {
            parameters["status"] = status.rawValue
        }
        
        if let sort = sort {
            parameters["sort"] = sort.rawValue
        }
        
        if let sortOrder = sortOrder {
            parameters["sort_order"] = sortOrder.rawValue
        }
        
        return try await performRequest(
            endpoint: "marketplace/orders",
            parameters: parameters
        )
    }
    
    /// Get a specific order by ID
    /// - Parameters:
    ///   - orderId: The ID of the order
    /// - Returns: An `Order` object.
    /// - Throws: A `DiscogsError` if the request fails.
    public func getOrder(orderId: String) async throws -> Order {
        try await performRequest(
            endpoint: "marketplace/orders/\(orderId)"
        )
    }
    
    /// Update an order's status
    /// - Parameters:
    ///   - orderId: The ID of the order
    ///   - status: The new status
    /// - Returns: An `Order` object.
    /// - Throws: A `DiscogsError` if the request fails.
    public func updateOrderStatus(
        orderId: String,
        status: OrderStatus
    ) async throws -> Order {
        let body = ["status": status.rawValue]
        
        return try await performRequest(
            endpoint: "marketplace/orders/\(orderId)",
            method: .post,
            body: body
        )
    }
    
    /// Add a shipping to an order
    /// - Parameters:
    ///   - orderId: The ID of the order
    ///   - value: The shipping cost
    /// - Returns: An `Order` object.
    /// - Throws: A `DiscogsError` if the request fails.
    public func addOrderShipping(
        orderId: String,
        value: String
    ) async throws -> Order {
        let body = ["shipping": value]
        
        return try await performRequest(
            endpoint: "marketplace/orders/\(orderId)/shipping",
            method: .post,
            body: body
        )
    }
    
    /// Add a message to an order
    /// - Parameters:
    ///   - orderId: The ID of the order
    ///   - message: The message text
    ///   - status: Optional new order status
    /// - Returns: An `OrderMessage` object.
    /// - Throws: A `DiscogsError` if the request fails.
    public func addOrderMessage(
        orderId: String,
        message: String,
        status: OrderStatus? = nil
    ) async throws -> OrderMessage {
        var body: [String: any Sendable] = ["message": message]
        
        if let status = status {
            body["status"] = status.rawValue
        }
        
        return try await performRequest(
            endpoint: "marketplace/orders/\(orderId)/messages",
            method: .post,
            body: body
        )
    }
    
    /// Get the price suggestions for a release
    /// - Parameters:
    ///   - releaseId: The ID of the release
    /// - Returns: A `PriceSuggestions` object.
    /// - Throws: A `DiscogsError` if the request fails.
    public func getPriceSuggestions(releaseId: Int) async throws -> PriceSuggestions {
        try await performRequest(
            endpoint: "marketplace/price_suggestions/\(releaseId)"
        )
    }
    
    /// Get marketplace statistics for a release
    /// - Parameters:
    ///   - releaseId: The ID of the release
    /// - Returns: A `ReleaseStats` object.
    /// - Throws: A `DiscogsError` if the request fails.
    public func getReleaseStats(releaseId: Int) async throws -> ReleaseStats {
        try await performRequest(
            endpoint: "marketplace/stats/\(releaseId)"
        )
    }
}

// MARK: - Enums

extension MarketplaceService {
    /// Sort fields for inventory
    public enum InventorySort: String, Sendable { // Added Sendable
        /// Sort by date listed
        case listed
        /// Sort by price
        case price
        /// Sort by artist name
        case artist
        /// Sort by title
        case title
        /// Sort by format
        case format
        /// Sort by condition
        case condition
        /// Sort by status
        case status
    }
    
    /// Sort fields for orders
    public enum OrderSort: String, Sendable { // Added Sendable
        /// Sort by ID
        case id
        /// Sort by buyer
        case buyer
        /// Sort by created date
        case created
        /// Sort by status
        case status
        /// Sort by last update
        case `updated`
    }
    
    /// Sort direction
    public enum SortOrder: String, Sendable { // Added Sendable
        /// Ascending order (A-Z, oldest to newest, lowest to highest)
        case ascending = "asc"
        /// Descending order (Z-A, newest to oldest, highest to lowest)
        case descending = "desc"
    }
    
    /// Item condition values
    public enum ItemCondition: String, Sendable { // Added Sendable
        /// Mint condition
        case mint = "Mint (M)"
        /// Near mint condition
        case nearMint = "Near Mint (NM or M-)"
        /// Very good plus condition
        case veryGoodPlus = "Very Good Plus (VG+)"
        /// Very good condition
        case veryGood = "Very Good (VG)"
        /// Good plus condition
        case goodPlus = "Good Plus (G+)"
        /// Good condition
        case good = "Good (G)"
        /// Fair condition
        case fair = "Fair (F)"
        /// Poor condition
        case poor = "Poor (P)"
    }
    
    /// Listing status values
    public enum ListingStatus: String, Sendable { // Added Sendable
        /// Draft listing (not yet active)
        case draft = "Draft"
        /// For sale
        case forSale = "For Sale"
        /// Expired
        case expired = "Expired"
        /// Sold
        case sold = "Sold"
        /// Deleted
        case deleted = "Deleted"
    }
    
    /// Order status values
    public enum OrderStatus: String, Sendable { // Added Sendable
        /// New order
        case newOrder = "New Order"
        /// Buyer contacted
        case buyerContacted = "Buyer Contacted"
        /// Invoice sent
        case invoiceSent = "Invoice Sent"
        /// Payment pending
        case paymentPending = "Payment Pending"
        /// Payment received
        case paymentReceived = "Payment Received"
        /// Shipped
        case shipped = "Shipped"
        /// Merged
        case merged = "Merged"
        /// Order changed
        case changed = "Order Changed"
        /// Cancelled
        case cancelled = "Cancelled"
        /// Cancelled (non-paying buyer)
        case cancelledNonPaying = "Cancelled (Non-Paying Buyer)"
        /// Refunded
        case refunded = "Refunded"
    }
}

// MARK: - Models

/// A marketplace listing
public struct Listing: Codable, Sendable { // Added Sendable
    /// The listing ID
    public let id: Int
    
    /// The resource URL
    public let resourceUrl: String?
    
    /// The URI
    public let uri: String?
    
    /// The listing status
    public let status: String
    
    /// The condition of the item
    public let condition: String
    
    /// The condition of the sleeve
    public let sleeveCondition: String?
    
    /// The asking price
    public let price: Price
    
    /// Whether offers are allowed
    public let allowOffers: Bool?
    
    /// The shipping price
    public let shipping: Price?
    
    /// The shipping options
    public let shippingOptions: [ShippingOption]?
    
    /// Comments about the item
    public let comments: String?
    
    /// When the listing was created
    public let posted: String?
    
    /// Ships from location
    public let shipsFrom: String?
    
    /// The ID of the release
    public let releaseId: Int?
    
    /// The seller
    public let seller: Seller
    
    /// Audio sample URL
    public let audioUrl: String?
    
    /// Whether audio sample is available
    public let audio: Bool?
    
    /// Audio sample information
    public let audioInfo: String?
    
    /// Thumbnail image URL
    public let thumb: String?
    
    /// Item condition description
    public let conditionDescription: String?
    
    /// Basic information about the release
    public let release: ReleaseBasicInfo?
    
    /// External ID (your own reference)
    public let externalId: String?
    
    /// Weight in grams
    public let weight: Int?
    
    /// Format quantity
    public let formatQuantity: Int?
    
    enum CodingKeys: String, CodingKey {
        case id
        case resourceUrl = "resource_url"
        case uri
        case status
        case condition
        case sleeveCondition = "sleeve_condition"
        case price
        case allowOffers = "allow_offers"
        case shipping
        case shippingOptions = "shipping_options"
        case comments
        case posted
        case shipsFrom = "ships_from"
        case releaseId = "release_id"
        case seller
        case audioUrl = "audio_url"
        case audio
        case audioInfo = "audio_info"
        case thumb
        case conditionDescription = "condition_description"
        case release
        case externalId = "external_id"
        case weight
        case formatQuantity = "format_quantity"
    }
}

/// A price with currency
public struct Price: Codable, Sendable { // Added Sendable
    /// The currency code
    public let currency: String
    
    /// The price value
    public let value: Double
}

/// Shipping option for a listing
public struct ShippingOption: Codable, Sendable { // Added Sendable
    /// The shipping option ID
    public let id: Int
    
    /// The shipping option name
    public let name: String
    
    /// The shipping option description
    public let description: String?
    
    /// The price
    public let price: Price
    
    /// The currency
    public let currency: String?
}

/// A seller profile
public struct Seller: Codable, Sendable { // Added Sendable
    /// The seller ID
    public let id: Int
    
    /// The seller's username
    public let username: String
    
    /// The seller's avatar URL
    public let avatarUrl: String?
    
    /// The seller's resource URL
    public let resourceUrl: String?
    
    /// The seller's location
    public let location: String?
    
    /// The seller's stats
    public let stats: SellerStats?
    
    /// The seller's rating
    public let rating: SellerRating?
    
    /// The seller's URL
    public let url: String?
    
    /// The seller's name
    public let name: String?
    
    /// The seller's payment options
    public let paymentOptions: [String]?
    
    /// The seller's shipping policies
    public let shippingPolicies: [String]?
}

/// A seller's stats
public struct SellerStats: Codable, Sendable { // Added Sendable
    /// The seller's rating
    public let rating: String?
    
    /// The number of ratings
    public let ratingCount: Int?
    
    /// The average rating
    public let averageRating: Double?
    
    /// The number of orders
    public let orders: Int?
}

/// A seller's rating
public struct SellerRating: Codable, Sendable { // Added Sendable
    /// The seller's average rating
    public let average: Double
    
    /// The count of ratings
    public let count: Int
    
    /// The last rating
    public let last: SellerLastRating?
}

/// A seller's last rating details
public struct SellerLastRating: Codable, Sendable { // Added Sendable
    /// The buyer's username
    public let buyerUsername: String?
    
    /// The rating value
    public let value: Int?
    
    /// The rating count
    public let count: Int?
    
    enum CodingKeys: String, CodingKey {
        case buyerUsername = "buyer_username"
        case value
        case count
    }
}

/// An order
public struct Order: Codable, Sendable { // Added Sendable
    /// The order ID
    public let id: String
    
    /// The resource URL
    public let resourceUrl: String
    
    /// The order messages URL
    public let messagesUrl: String
    
    /// The URI
    public let uri: String
    
    /// The order status
    public let status: String
    
    /// The next status options
    public let nextStatusOptions: [String]?
    
    /// The next status (computed)
    public var nextStatus: [String]? { nextStatusOptions }
    
    /// The fee for this order
    public let fee: Price?
    
    /// The message from the buyer
    public let message: String?
    
    /// When the order was created
    public let created: String
    
    /// When the order was last updated
    public let updated: String?
    
    /// The shipping address
    public let shippingAddress: String?
    
    /// Additional shipping instructions
    public let additionalInstructions: String?
    
    /// The shipping amount
    public let shipping: Price?
    
    /// The shipping service selected
    public let shippingService: String?
    
    /// The shipping tracking number
    public let trackingNumber: String?
    
    /// The shipping URL
    public let trackingUrl: String?
    
    /// The buyer information
    public let buyer: Buyer?
    
    /// The seller information
    public let seller: Seller
    
    /// The items in this order
    public let items: [OrderItem]
    
    /// The total price
    public let total: Price
    
    /// The last message in the order
    public let lastMessage: String?
    
    /// The order's archived status
    public let archived: Bool?
    
    /// Whether the order needs response
    public let needsResponse: Bool?
    
    /// Order contact information
    public let contactRecordUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case resourceUrl = "resource_url"
        case messagesUrl = "messages_url"
        case uri
        case status
        case nextStatusOptions = "next_status_options"
        case fee
        case message
        case created
        case updated
        case shippingAddress = "shipping_address"
        case additionalInstructions = "additional_instructions"
        case shipping
        case shippingService = "shipping_service"
        case trackingNumber = "tracking_number"
        case trackingUrl = "tracking_url"
        case buyer
        case seller
        case items
        case total
        case lastMessage = "last_message"
        case archived
        case needsResponse = "needs_response"
        case contactRecordUrl = "contact_record_url"
    }
}

/// A buyer
public struct Buyer: Codable, Sendable { // Added Sendable
    /// The buyer's ID
    public let id: Int
    
    /// The buyer's username
    public let username: String
    
    /// The buyer's resource URL
    public let resourceUrl: String
    
    /// The buyer's avatar URL
    public let avatarUrl: String?
    
    /// The buyer's location
    public let location: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case resourceUrl = "resource_url"
        case avatarUrl = "avatar_url"
        case location
    }
}

/// An item in an order
public struct OrderItem: Codable, Sendable { // Added Sendable
    /// The item ID
    public let id: Int
    
    /// The resource URL
    public let resourceUrl: String
    
    /// The description
    public let description: String?
    
    /// The media condition
    public let mediaCondition: String?
    
    /// The sleeve condition
    public let sleeveCondition: String?
    
    /// The price
    public let price: Price
    
    /// The release details
    public let release: OrderItemRelease?
    
    /// The item quantity
    public let quantity: Int?
    
    enum CodingKeys: String, CodingKey {
        case id
        case resourceUrl = "resource_url"
        case description
        case mediaCondition = "media_condition"
        case sleeveCondition = "sleeve_condition"
        case price
        case release
        case quantity
    }
}

/// A release in an order item
public struct OrderItemRelease: Codable, Sendable { // Added Sendable
    /// The release ID
    public let id: Int
    
    /// The resource URL
    public let resourceUrl: String
    
    /// The thumbnail URL
    public let thumbnail: String?
    
    /// The description
    public let description: String?
    
    /// The release format
    public let format: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case resourceUrl = "resource_url"
        case thumbnail
        case description
        case format
    }
}

/// A message in an order
public struct OrderMessage: Codable, Sendable { // Added Sendable
    /// The message content
    public let message: String
    
    /// The date and time the message was created
    public let timestamp: String
    
    /// The subject of the message
    public let subject: String?
    
    /// The sender of the message
    public let from: UserReference
    
    /// The order status when the message was sent
    public let status: String?
}

/// Price suggestions for a release
public struct PriceSuggestions: Codable, Sendable { // Added Sendable
    /// The median price
    public let median: Price?
    
    /// The minimum price
    public let minimum: Price?
    
    /// The maximum price
    public let maximum: Price?
}

/// A price suggestion for a specific condition
public struct PriceSuggestion: Codable, Sendable { // Added Sendable
    /// The suggested price
    public let value: Double
    
    /// The currency
    public let currency: String
}

/// Release statistics from the marketplace
public struct ReleaseStatistics: Codable, Sendable { // Added Sendable
    /// The number of items for sale
    public let numForSale: Int
    
    /// The lowest price
    public let lowestPrice: Price?
    
    /// The number of items sold in the past
    public let numSold: Int?
    
    /// The last sold price
    public let lastSoldPrice: Price?
    
    /// Coding keys used for decoding
    private enum CodingKeys: String, CodingKey {
        case numForSale = "num_for_sale"
        case lowestPrice = "lowest_price"
        case numSold = "num_sold"
        case lastSoldPrice = "last_sold_price"
    }
}
