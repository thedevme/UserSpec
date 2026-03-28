import Foundation
import UserSpec

// MARK: - User Fixtures

extension User: Buildable {
    public static var defaultValue: User {
        User(
            name: "Test User",
            email: "test@example.com",
            membershipTier: .standard
        )
    }
}

extension User: FixtureProviding {
    public static var fixtures: [String: User] {
        [
            "standard": User(name: "Standard User", email: "standard@example.com", membershipTier: .standard),
            "premium": User(name: "Premium User", email: "premium@example.com", membershipTier: .premium),
            "vip": User(name: "VIP User", email: "vip@example.com", membershipTier: .vip),
        ]
    }
}

// MARK: - Product Fixtures

extension Product: Buildable {
    public static var defaultValue: Product {
        Product(
            name: "Test Product",
            price: 9.99,
            category: .general,
            inStock: true
        )
    }
}

extension Product: FixtureProviding {
    public static var fixtures: [String: Product] {
        [
            "book": Product(name: "Swift Programming", price: 49.99, category: .books),
            "laptop": Product(name: "MacBook Pro", price: 1999.00, category: .electronics),
            "shirt": Product(name: "T-Shirt", price: 29.99, category: .clothing),
            "outOfStock": Product(name: "Sold Out Item", price: 99.99, category: .general, inStock: false),
        ]
    }
}

// MARK: - Cart Fixtures

extension Cart: Buildable {
    public static var defaultValue: Cart {
        Cart()
    }
}

// MARK: - Coupon Fixtures

extension Coupon: Buildable {
    public static var defaultValue: Coupon {
        Coupon(code: "TEST10", discountPercentage: 10, minimumPurchase: 0)
    }
}

extension Coupon: FixtureProviding {
    public static var fixtures: [String: Coupon] {
        [
            "10off": Coupon(code: "SAVE10", discountPercentage: 10, minimumPurchase: 0),
            "20off": Coupon(code: "SAVE20", discountPercentage: 20, minimumPurchase: 50),
            "vipOnly": Coupon(code: "VIP50", discountPercentage: 50, minimumPurchase: 100),
        ]
    }
}
