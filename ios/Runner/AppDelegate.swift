import UIKit
import Flutter
import Firebase
import StoreKit

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()
    GeneratedPluginRegistrant.register(with: self)
    
    // 保留中のトランザクションを完了させる
    SKPaymentQueue.default().add(self)
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

extension AppDelegate: SKPaymentTransactionObserver {
  func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
    for transaction in transactions {
      switch transaction.transactionState {
      case .purchased, .restored:
        SKPaymentQueue.default().finishTransaction(transaction)
      case .failed:
        SKPaymentQueue.default().finishTransaction(transaction)
      case .deferred, .purchasing:
        break
      @unknown default:
        break
      }
    }
  }
}