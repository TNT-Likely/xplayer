import Foundation
import StoreKit
#if os(iOS)
import Flutter
#else
import FlutterMacOS
#endif

public final class XPlayerStorePlugin: NSObject, FlutterPlugin {
    private let channel: FlutterMethodChannel
    private var updates: Task<Void, Never>?
    private let tiers: Set<String> = ["monthly", "yearly", "lifetime"]
    private let prefix = "com.tntlikely.xplayer.pro."

    init(channel: FlutterMethodChannel) {
        self.channel = channel
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        #if os(iOS)
        let messenger = registrar.messenger()
        #else
        let messenger = registrar.messenger
        #endif
        let channel = FlutterMethodChannel(name: "xplayer/membership", binaryMessenger: messenger)
        registrar.addMethodCallDelegate(XPlayerStorePlugin(channel: channel), channel: channel)
    }

    deinit { updates?.cancel() }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard #available(iOS 15, macOS 12, *) else {
            if call.method == "state" { result(["supported": false, "active": []]) }
            else { result(FlutterError(code: "unsupported", message: nil, details: nil)) }
            return
        }
        Task { @MainActor in
            do {
                switch call.method {
                case "state":
                    listen()
                    result(await state())
                case "products":
                    let products = try await Product.products(for: tiers.map { prefix + $0 })
                    result(Dictionary(uniqueKeysWithValues: products.map { ($0.id, $0.displayPrice) }))
                case "buy":
                    guard let id = call.arguments as? String, recognizes(id),
                          let product = try await Product.products(for: [id]).first else {
                        result(FlutterError(code: "unavailable", message: nil, details: nil))
                        return
                    }
                    switch try await product.purchase() {
                    case .success(let verification):
                        guard case .verified(let transaction) = verification, transaction.productID == id else {
                            result(FlutterError(code: "unverified", message: nil, details: nil))
                            return
                        }
                        await transaction.finish()
                        result("purchased")
                    case .pending: result("pending")
                    case .userCancelled: result("cancelled")
                    @unknown default: result("pending")
                    }
                case "restore":
                    try await AppStore.sync()
                    result(await state())
                default: result(FlutterMethodNotImplemented)
                }
            } catch StoreKitError.userCancelled {
                if call.method == "buy" { result("cancelled") }
                else { result(FlutterError(code: "cancelled", message: nil, details: nil)) }
            } catch {
                result(FlutterError(code: "store_error", message: error.localizedDescription, details: nil))
            }
        }
    }

    private func recognizes(_ id: String) -> Bool {
        id.hasPrefix(prefix) && tiers.contains(String(id.dropFirst(prefix.count)))
    }

    @available(iOS 15, macOS 12, *)
    @MainActor private func listen() {
        guard updates == nil else { return }
        updates = Task { [weak self] in
            for await change in Transaction.updates {
                guard let self = self, !Task.isCancelled else { return }
                await self.receive(change)
            }
        }
        Task { [weak self] in
            for await change in Transaction.unfinished {
                await self?.receive(change)
            }
        }
    }

    @available(iOS 15, macOS 12, *)
    @MainActor private func receive(_ change: VerificationResult<Transaction>) async {
        guard case .verified(let transaction) = change, recognizes(transaction.productID) else { return }
        await transaction.finish()
        channel.invokeMethod("changed", arguments: nil)
    }

    @available(iOS 15, macOS 12, *)
    private func state() async -> [String: Any] {
        var active: [String] = []
        var expirations: [Date] = []
        // StoreKit includes subscriptions in billing grace and excludes expired/refunded purchases.
        for await entitlement in Transaction.currentEntitlements {
            guard case .verified(let tx) = entitlement, recognizes(tx.productID),
                  tx.revocationDate == nil, !tx.isUpgraded else { continue }
            active.append(tx.productID)
            if let end = tx.expirationDate { expirations.append(end) }
        }
        var data: [String: Any] = ["supported": true, "active": active]
        if let end = expirations.min() {
            data["expires"] = Int64(end.timeIntervalSince1970 * 1000)
        }
        return data
    }
}
