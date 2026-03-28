import Testing
import UserSpec
@testable import UserSpecExamples

// MARK: - Shared Example Definitions

/// Context for testing membership benefits
struct MembershipContext {
    let user: User
    let expectedDiscount: Decimal
}

/// Define shared examples once, use everywhere
func setupSharedExamples() {
    SharedExamples.define("applies membership discount") { (context: MembershipContext) in
        try given("a user with \(context.user.membershipTier) membership") {
            context.user
        }
        .when("calculating their discount") { user in
            switch user.membershipTier {
            case .standard: return Decimal(0)
            case .premium: return Decimal(10)
            case .vip: return Decimal(20)
            }
        }
        .then("the discount is \(context.expectedDiscount)%") { discount, _ in
            #expect(discount == context.expectedDiscount)
        }
    }
}

// MARK: - Using Shared Examples

@UserStory("As a member, I want to receive discounts based on my tier")
struct MembershipDiscountSpec {

    init() {
        setupSharedExamples()
    }

    @Test
    @Scenario("Standard members get no discount")
    func standardMemberDiscount() throws {
        try itBehavesLike("applies membership discount", context: MembershipContext(
            user: User.fixture("standard"),
            expectedDiscount: 0
        ))
    }

    @Test
    @Scenario("Premium members get 10% discount")
    func premiumMemberDiscount() throws {
        try itBehavesLike("applies membership discount", context: MembershipContext(
            user: User.fixture("premium"),
            expectedDiscount: 10
        ))
    }

    @Test
    @Scenario("VIP members get 20% discount")
    func vipMemberDiscount() throws {
        try itBehavesLike("applies membership discount", context: MembershipContext(
            user: User.fixture("vip"),
            expectedDiscount: 20
        ))
    }
}

// MARK: - Using SharedBehavior Protocol

/// A reusable behavior that verifies cart calculations
struct CartCalculationBehavior: SharedBehavior {
    let cart: Cart
    let expectedSubtotal: Decimal
    let expectedTotal: Decimal

    func execute() throws {
        try given("a cart with items") {
            cart
        }
        .when("calculating totals") { cart in
            (subtotal: cart.subtotal, total: cart.total)
        }
        .then("totals are correct") { totals, _ in
            #expect(totals.subtotal == expectedSubtotal)
            #expect(totals.total == expectedTotal)
        }
    }
}

@UserStory("As a shopper, I want accurate cart totals")
struct CartCalculationSpec {

    @Test
    @Scenario("Empty cart has zero total")
    func emptyCartTotal() throws {
        try CartCalculationBehavior(
            cart: Cart(),
            expectedSubtotal: 0,
            expectedTotal: 0
        ).execute()
    }

    @Test
    @Scenario("Cart with items calculates correctly")
    func cartWithItemsTotal() throws {
        var cart = Cart()
        _ = cart.add(Product.build { $0.price = 25 })
        _ = cart.add(Product.build { $0.price = 75 })

        try CartCalculationBehavior(
            cart: cart,
            expectedSubtotal: 100,
            expectedTotal: 100
        ).execute()
    }

    @Test
    @Scenario("Cart with coupon calculates discount")
    func cartWithCouponTotal() throws {
        var cart = Cart()
        _ = cart.add(Product.build { $0.price = 100 })
        _ = cart.applyCoupon(Coupon.fixture("10off"))

        try CartCalculationBehavior(
            cart: cart,
            expectedSubtotal: 100,
            expectedTotal: 90
        ).execute()
    }
}
