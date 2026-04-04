// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Flutter
import UIKit

/// Protocol for UIViewController methods relating to presenting a controller.
///
/// This protocol exists to allow injecting an alternate implementation for testing.
protocol ViewPresenter {
  /// Presents a view controller modally.
  func present(
    _ viewControllerToPresent: UIViewController,
    animated flag: Bool,
    completion: (() -> Void)?
  )
}

/// ViewPresenter is intentionally a direct passthroguh to UIViewController.
extension UIViewController: ViewPresenter {}

/// Protocol for FlutterPluginRegistrar method for accessing the view controller.
///
/// This is necessary because Swift doesn't allow for only partially implementing a protocol, so
/// a stub implementation of FlutterPluginRegistrar for tests would break any time something was
/// added to that protocol.
protocol ViewPresenterProvider {
  /// Returns the view presenter associated with the Flutter content.
  var viewPresenter: ViewPresenter? { get }
}

/// Non-test implementation of ViewPresenterProvider that forwards to the plugin registrar.
final class DefaultViewPresenterProvider: ViewPresenterProvider {
  private let registrar: FlutterPluginRegistrar
  private let registrarViewControllerSelector = NSSelectorFromString("viewController")

  init(registrar: FlutterPluginRegistrar) {
    self.registrar = registrar
  }

  var viewPresenter: ViewPresenter? {
    if let registrarObject = registrar as? NSObject,
      registrarObject.responds(to: registrarViewControllerSelector),
      let unmanagedViewController = registrarObject.perform(registrarViewControllerSelector),
      let viewController = unmanagedViewController.takeUnretainedValue() as? UIViewController
    {
      return viewController
    }

    return topViewController(from: rootViewController())
  }

  private func rootViewController() -> UIViewController? {
    let foregroundScene = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .first { $0.activationState == .foregroundActive }
    let keyWindow = foregroundScene?.windows.first { $0.isKeyWindow }
      ?? UIApplication.shared.windows.first { $0.isKeyWindow }
    return keyWindow?.rootViewController
  }

  private func topViewController(from viewController: UIViewController?) -> UIViewController? {
    if let navigationController = viewController as? UINavigationController {
      return topViewController(from: navigationController.visibleViewController)
    }
    if let tabBarController = viewController as? UITabBarController {
      return topViewController(from: tabBarController.selectedViewController)
    }
    if let presentedViewController = viewController?.presentedViewController {
      return topViewController(from: presentedViewController)
    }
    return viewController
  }
}
