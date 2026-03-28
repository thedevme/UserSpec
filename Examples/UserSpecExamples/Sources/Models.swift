import Foundation

// MARK: - User

public struct User: Sendable, Equatable {
    public var id: UUID
    public var name: String
    public var email: String
    public var membershipTier: MembershipTier

    public init(
        id: UUID = UUID(),
        name: String,
        email: String,
        membershipTier: MembershipTier = .standard
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.membershipTier = membershipTier
    }

    public enum MembershipTier: String, Sendable {
        case standard
        case premium
        case vip
    }
}

// MARK: - Product

public struct Product: Sendable, Equatable, Identifiable {
    public var id: UUID
    public var name: String
    public var price: Decimal
    public var category: Category
    public var inStock: Bool

    public init(
        id: UUID = UUID(),
        name: String,
        price: Decimal,
        category: Category = .general,
        inStock: Bool = true
    ) {
        self.id = id
        self.name = name
        self.price = price
        self.category = category
        self.inStock = inStock
    }

    public enum Category: String, Sendable {
        case electronics
        case clothing
        case books
        case general
    }
}

// MARK: - Cart

public struct Cart: Sendable {
    public var items: [CartItem]
    public var appliedCoupon: Coupon?

    public init(items: [CartItem] = [], appliedCoupon: Coupon? = nil) {
        self.items = items
        self.appliedCoupon = appliedCoupon
    }

    public var subtotal: Decimal {
        items.reduce(0) { $0 + $1.total }
    }

    public var discount: Decimal {
        guard let coupon = appliedCoupon else { return 0 }
        return subtotal * coupon.discountPercentage / 100
    }

    public var total: Decimal {
        subtotal - discount
    }

    public var isEmpty: Bool {
        items.isEmpty
    }

    public var itemCount: Int {
        items.reduce(0) { $0 + $1.quantity }
    }

    public mutating func add(_ product: Product, quantity: Int = 1) -> CartResult {
        guard product.inStock else {
            return .failure(.outOfStock)
        }
        guard quantity > 0 else {
            return .failure(.invalidQuantity)
        }

        if let index = items.firstIndex(where: { $0.product.id == product.id }) {
            items[index].quantity += quantity
        } else {
            items.append(CartItem(product: product, quantity: quantity))
        }
        return .success
    }

    public mutating func remove(_ productId: UUID) -> CartResult {
        guard items.contains(where: { $0.product.id == productId }) else {
            return .failure(.itemNotFound)
        }
        items.removeAll { $0.product.id == productId }
        return .success
    }

    public mutating func applyCoupon(_ coupon: Coupon) -> CartResult {
        guard subtotal >= coupon.minimumPurchase else {
            return .failure(.couponMinimumNotMet)
        }
        appliedCoupon = coupon
        return .success
    }

    public mutating func clear() {
        items.removeAll()
        appliedCoupon = nil
    }
}

// MARK: - Cart Item

public struct CartItem: Sendable, Equatable {
    public var product: Product
    public var quantity: Int

    public init(product: Product, quantity: Int = 1) {
        self.product = product
        self.quantity = quantity
    }

    public var total: Decimal {
        product.price * Decimal(quantity)
    }
}

// MARK: - Coupon

public struct Coupon: Sendable, Equatable {
    public var code: String
    public var discountPercentage: Decimal
    public var minimumPurchase: Decimal

    public init(code: String, discountPercentage: Decimal, minimumPurchase: Decimal = 0) {
        self.code = code
        self.discountPercentage = discountPercentage
        self.minimumPurchase = minimumPurchase
    }
}

// MARK: - Cart Result

public enum CartResult: Sendable, Equatable {
    case success
    case failure(CartError)

    public enum CartError: String, Sendable {
        case outOfStock
        case invalidQuantity
        case itemNotFound
        case couponMinimumNotMet
    }
}

// MARK: - Order

public struct Order: Sendable {
    public var id: UUID
    public var user: User
    public var items: [CartItem]
    public var total: Decimal
    public var status: Status

    public init(
        id: UUID = UUID(),
        user: User,
        items: [CartItem],
        total: Decimal,
        status: Status = .pending
    ) {
        self.id = id
        self.user = user
        self.items = items
        self.total = total
        self.status = status
    }

    public enum Status: String, Sendable {
        case pending
        case confirmed
        case shipped
        case delivered
        case cancelled
    }
}
