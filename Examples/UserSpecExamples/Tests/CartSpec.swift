import Testing
import UserSpec
@testable import UserSpecExamples

// MARK: - Cart User Stories

@UserStory("As a shopper, I want to add items to my cart so I can purchase them later")
struct AddToCartSpec {

    @Test
    @Scenario("Adding an in-stock product increases cart count")
    func addInStockProduct() throws {
        try given("an empty cart and an in-stock product") {
            (cart: Cart(), product: Product.fixture("book"))
        }
        .when("the product is added to the cart") { context in
            var cart = context.cart
            let result = cart.add(context.product)
            return (cart: cart, result: result)
        }
        .then("the cart contains one item") { result, _ in
            #expect(result.result == .success)
            #expect(result.cart.itemCount == 1)
            #expect(result.cart.isEmpty == false)
        }
    }

    @Test
    @Scenario("Adding an out-of-stock product fails")
    func addOutOfStockProduct() throws {
        try given("an empty cart and an out-of-stock product") {
            (cart: Cart(), product: Product.fixture("outOfStock"))
        }
        .when("the product is added to the cart") { context in
            var cart = context.cart
            let result = cart.add(context.product)
            return (cart: cart, result: result)
        }
        .then("the operation fails with out of stock error") { result, _ in
            #expect(result.result == .failure(.outOfStock))
            #expect(result.cart.isEmpty == true)
        }
    }

    @Test
    @Scenario("Adding the same product twice increases quantity")
    func addSameProductTwice() throws {
        try given("a cart with one book") {
            var cart = Cart()
            _ = cart.add(Product.fixture("book"))
            return cart
        }
        .when("the same book is added again") { cart in
            var cart = cart
            _ = cart.add(Product.fixture("book"))
            return cart
        }
        .then("the cart has quantity of 2") { cart, _ in
            #expect(cart.itemCount == 2)
            #expect(cart.items.count == 1) // Still one line item
            #expect(cart.items.first?.quantity == 2)
        }
    }
}

@UserStory("As a shopper, I want to remove items from my cart so I can change my mind")
struct RemoveFromCartSpec {

    @Test
    @Scenario("Removing an existing item succeeds")
    func removeExistingItem() throws {
        let product = Product.fixture("book")

        try given("a cart with one item") {
            var cart = Cart()
            _ = cart.add(product)
            return cart
        }
        .when("the item is removed") { cart in
            var cart = cart
            let result = cart.remove(product.id)
            return (cart: cart, result: result)
        }
        .then("the cart is empty") { result, _ in
            #expect(result.result == .success)
            #expect(result.cart.isEmpty == true)
        }
    }

    @Test
    @Scenario("Removing a non-existent item fails")
    func removeNonExistentItem() throws {
        try given("an empty cart") {
            Cart()
        }
        .when("attempting to remove a random product ID") { cart in
            var cart = cart
            let result = cart.remove(UUID())
            return result
        }
        .then("the operation fails") { result, _ in
            #expect(result == .failure(.itemNotFound))
        }
    }
}

@UserStory("As a shopper, I want to apply coupons so I can save money")
struct ApplyCouponSpec {

    @Test
    @Scenario("Valid coupon reduces total")
    func validCouponReducesTotal() throws {
        try given("a cart with items totaling $100") {
            var cart = Cart()
            let product = Product.build { $0.price = 100 }
            _ = cart.add(product)
            return cart
        }
        .when("a 10% off coupon is applied") { cart in
            var cart = cart
            let coupon = Coupon.fixture("10off")
            _ = cart.applyCoupon(coupon)
            return cart
        }
        .then("the total is reduced by 10%") { cart, _ in
            #expect(cart.subtotal == 100)
            #expect(cart.discount == 10)
            #expect(cart.total == 90)
        }
    }

    @Test
    @Scenario("Coupon with minimum purchase requirement fails if not met")
    func couponMinimumNotMet() throws {
        try given("a cart with items totaling $30") {
            var cart = Cart()
            let product = Product.build { $0.price = 30 }
            _ = cart.add(product)
            return cart
        }
        .when("a coupon requiring $50 minimum is applied") { cart in
            var cart = cart
            let coupon = Coupon.fixture("20off") // requires $50 minimum
            let result = cart.applyCoupon(coupon)
            return (cart: cart, result: result)
        }
        .then("the coupon is rejected") { result, _ in
            #expect(result.result == .failure(.couponMinimumNotMet))
            #expect(result.cart.appliedCoupon == nil)
        }
    }
}
