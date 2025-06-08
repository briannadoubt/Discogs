import Foundation
@testable import Discogs

let ordersJson = """
{
    "pagination": {
        "page": 1,
        "pages": 2,
        "per_page": 50,
        "items": 75
    },
    "orders": [
        {
            "id": "order-123",
            "status": "Payment Pending",
            "created": "2023-06-05T14:30:00-08:00",
            "total": {
                "currency": "USD",
                "value": 45.98
            },
            "buyer": {
                "id": 456,
                "username": "buyer123",
                "resource_url": "https://api.discogs.com/users/buyer123"
            },
            "items": [
                {
                    "id": 123,
                    "release": {
                        "id": 1,
                        "title": "Abbey Road"
                    },
                    "price": {
                        "currency": "USD",
                        "value": 25.99
                    }
                }
            ]
        }
    ]
}
""".data(using: .utf8)!

let decoder = JSONDecoder()
do {
    let orders = try decoder.decode(PaginatedResponse<Order>.self, from: ordersJson)
    print("✅ Decoded orders successfully!")
    print("- Orders count: \(orders.items.count)")
    if let firstOrder = orders.items.first {
        print("- First order ID: \(firstOrder.id)")
        print("- First order status: \(firstOrder.status)")
    }
} catch {
    print("❌ Failed to decode orders: \(error)")
}
