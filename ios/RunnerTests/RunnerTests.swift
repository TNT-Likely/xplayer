import Flutter
import StoreKitTest
import XCTest
@testable import xplayer_storekit

@available(iOS 15, *)
@MainActor
final class RunnerTests: XCTestCase {
    private let prefix = "com.tntlikely.xplayer.pro."

    func testStoreKitMembershipLifecycle() async throws {
        let url = try XCTUnwrap(Bundle(for: Self.self).url(forResource: "XPlayerPro", withExtension: "storekit"))
        let session = try SKTestSession(contentsOf: url)
        session.resetToDefaultState()
        session.clearTransactions()
        session.disableDialogs = true
        session.storefront = "USA"
        defer { session.clearTransactions() }

        let engine = FlutterEngine(name: "storekit-test")
        let channel = FlutterMethodChannel(name: "xplayer/test-entitlements", binaryMessenger: engine.binaryMessenger)
        let store = XPlayerStorePlugin(channel: channel)
        func call(_ method: String, _ args: String? = nil) async throws -> Any? {
            try await withCheckedThrowingContinuation { continuation in
                store.handle(FlutterMethodCall(methodName: method, arguments: args)) { value in
                    if let error = value as? FlutterError {
                        continuation.resume(throwing: NSError(domain: error.code, code: 1))
                    } else { continuation.resume(returning: value) }
                }
            }
        }
        func waitFor(_ plans: [String]) async throws {
            let target = Set(plans.map { prefix + $0 })
            var current: Set<String> = []
            for _ in 0..<40 {
                let data = try await call("state") as? [String: Any]
                current = Set(data?["active"] as? [String] ?? [])
                if current == target { return }
                try await Task.sleep(nanoseconds: 200_000_000)
            }
            XCTAssertEqual(current, target)
        }

        let products = try await call("products") as? [String: String]
        XCTAssertEqual(Set(products?.keys.map { $0 } ?? []), Set(["monthly", "yearly", "lifetime"].map { prefix + $0 }))
        try await waitFor([])
        let monthly = try await call("buy", prefix + "monthly") as? String
        XCTAssertEqual(monthly, "purchased")
        try await waitFor(["monthly"])
        try session.expireSubscription(productIdentifier: prefix + "monthly")
        try await waitFor([])

        let yearly = try await call("buy", prefix + "yearly") as? String
        XCTAssertEqual(yearly, "purchased")
        try await waitFor(["yearly"])
        let lifetime = try await call("buy", prefix + "lifetime") as? String
        XCTAssertEqual(lifetime, "purchased")
        try await waitFor(["yearly", "lifetime"])
        let restored = try await call("restore") as? [String: Any]
        XCTAssertTrue((restored?["active"] as? [String] ?? []).contains(prefix + "lifetime"))

        try session.expireSubscription(productIdentifier: prefix + "yearly")
        try await waitFor(["lifetime"])
        let transaction = try XCTUnwrap(session.allTransactions().first { $0.productIdentifier == prefix + "lifetime" })
        try session.refundTransaction(identifier: transaction.identifier)
        try await waitFor([])
    }
}
