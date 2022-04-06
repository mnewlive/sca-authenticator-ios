//
//  ApplicationCoordinator.swift
//  This file is part of the Salt Edge Authenticator distribution
//  (https://github.com/saltedge/sca-authenticator-ios)
//  Copyright © 2019 Salt Edge Inc.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, version 3 or later.
//
//  This program is distributed in the hope that it will be useful, but
//  WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
//  General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program. If not, see <http://www.gnu.org/licenses/>.
//
//  For the additional permissions granted for Salt Edge Authenticator
//  under Section 7 of the GNU General Public License see THIRD_PARTY_NOTICES.md
//

import UIKit
import SEAuthenticatorCore

final class ApplicationCoordinator: Coordinator {
    private let window: UIWindow?
    private var qrCodeCoordinator: QRCodeCoordinator?
    private var passcodeCoordinator: PasscodeCoordinator?
    private var instantActionCoordinator: InstantActionCoordinator?
    private var connectViewCoordinator: ConnectViewCoordinator?

    private lazy var authorizationsCoordinator = AuthorizationsCoordinator()

    private var authorizationsNavController: UINavigationController {
        return UINavigationController(rootViewController: authorizationsCoordinator.rootViewController)
    }

    private var passcodeShownDueToInactivity: Bool = false

    private var messageBarView: MessageBarView?

    init(window: UIWindow?) {
        self.window = window
        UserDefaultsHelper.applicationLanguage = "en"
    }

    func start() {
        if UserDefaultsHelper.didShowOnboarding {
            registerTimerNotifications()
            window?.rootViewController = authorizationsNavController
            authorizationsCoordinator.start()
        } else {
            PasscodeManager.remove()

            setOnboardingAsRootController()
        }
        window?.makeKeyAndVisible()
    }

    func swapToOnboarding() {
        guard let window = window else { return }

        UIView.transition(
            with: window,
            duration: 0.3,
            options: .transitionCrossDissolve,
            animations: {
                UserDefaultsHelper.didShowOnboarding = false
                PasscodeManager.remove()
                self.disableTimerNotifications()
                self.setOnboardingAsRootController()
            }
        )
    }

    private func setOnboardingAsRootController() {
        let onboardingVc = OnboardingViewController()
        onboardingVc.modalPresentationStyle = .fullScreen
        window?.rootViewController = onboardingVc

        onboardingVc.donePressedClosure = {
            let setupVc = SetupAppViewController()
            setupVc.delegate = self
            setupVc.modalPresentationStyle = .fullScreen
            onboardingVc.present(setupVc, animated: true)
        }
    }

    private func startAuthorizationsViewController() {
        UserDefaultsHelper.didShowOnboarding = true

        registerTimerNotifications()

        window?.rootViewController = authorizationsNavController
        authorizationsCoordinator.start()
    }

    func registerTimerNotifications() {
        disableTimerNotifications()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidTimeout(notification:)),
            name: .appTimeout,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(dismissMessage),
            name: .resetTimer,
            object: nil
        )
    }

    func disableTimerNotifications() {
        NotificationCenter.default.removeObserver(self, name: .appTimeout, object: nil)
        NotificationCenter.default.removeObserver(self, name: .resetTimer, object: nil)
    }

    func stop() {}

    func showAuthorizations(connectionId: String, authorizationId: String) {
        authorizationsCoordinator.start(with: connectionId, authorizationId: authorizationId)
    }

    func openQrScannerIfNoConnections() {
        if ConnectionsCollector.activeConnections.isEmpty {
            openQrScanner()
        }
    }

    func openQrScanner() {
        passcodeCoordinator?.onCompleteClosure = {
            guard let rootNavVc = self.window?.rootViewController as? UINavigationController,
                !rootNavVc.isKind(of: OnboardingViewController.self),
                let topControler = UIWindow.topViewController,
                !topControler.isKind(of: QRCodeViewController.self) else { return }

            rootNavVc.setViewControllers([self.authorizationsCoordinator.rootViewController], animated: true)

            guard AVCaptureHelper.cameraIsAuthorized() else { return }

            self.qrCodeCoordinator = QRCodeCoordinator(rootViewController: rootNavVc)
            self.qrCodeCoordinator?.start()
        }
    }

    func openConnectViewController(url: URL) {
        passcodeCoordinator?.onCompleteClosure = {
            guard let topController = UIWindow.topViewController, SEConnectHelper.isValid(deepLinkUrl: url) else { return }

            self.startConnect(url: url, controller: topController)
        }
    }

    func handleAuthorizationsFromPasscode(connectionId: String, authorizationId: String) {
        passcodeCoordinator?.onCompleteClosure = {
            self.showAuthorizations(connectionId: connectionId, authorizationId: authorizationId)
        }
    }

    func openPasscodeIfNeeded() {
        removeAlertControllerIfPresented()

        if let passcodeVC = UIWindow.topViewController as? PasscodeViewController {
            passcodeVC.dismiss(animated: false, completion: presentPasscode)
        } else {
            presentPasscode()
        }
    }

    func showBiometricsIfEnabled() {
        if UserDefaultsHelper.blockedTill == nil, let passcodeCoordinator = passcodeCoordinator {
            passcodeCoordinator.showBiometrics()
        }
    }

    private func presentPasscode() {
        guard let topController = UIWindow.topViewController, UserDefaultsHelper.didShowOnboarding else { return }

        passcodeCoordinator = PasscodeCoordinator(
            rootViewController: topController,
            purpose: .enter
        )
        passcodeCoordinator?.onCompleteClosure = {
            TimerApplication.resetIdleTimer()
            self.registerTimerNotifications()
        }
        passcodeCoordinator?.start()
    }

    private func removeAlertControllerIfPresented() {
        if let alertViewController = UIWindow.topViewController as? UIAlertController {
            alertViewController.dismiss(animated: false)
        }
    }

    @objc func applicationDidTimeout(notification: NSNotification) {
        guard let topController = UIWindow.topViewController,
            !topController.isKind(of: PasscodeViewController.self),
            !topController.isKind(of: ForgotPasscodeViewController.self) else { return }

        if topController.isKind(of: UIAlertController.self) {
            topController.dismiss(
                animated: true,
                completion: {
                    self.presentInactivityMessage(from: self.window?.rootViewController)
                }
            )
        } else {
            presentInactivityMessage(from: topController)
        }
    }

    private func presentInactivityMessage(from controller: UIViewController?) {
        guard let controller = controller else { return }

        messageBarView = controller.present(
            message: l10n(.inactivityMessage),
            completion: {
                if self.messageBarView != nil {
                    self.passcodeShownDueToInactivity = true
                    self.disableTimerNotifications()
                    self.openPasscodeIfNeeded()
                    self.showBiometricsIfEnabled()
                }
            }
        )
    }

    @objc private func dismissMessage() {
        if let messageView = messageBarView, let topController = UIWindow.topViewController {
            topController.dismiss(messageBarView: messageView)
            messageBarView = nil
        }
    }

    private func startConnect(url: URL, controller: UIViewController) {
        if SEConnectHelper.shouldStartInstantActionFlow(url: url) {
            instantActionCoordinator = InstantActionCoordinator(
                rootViewController: controller,
                qrUrl: url
            )
            instantActionCoordinator?.start()
        } else {
            connectViewCoordinator = ConnectViewCoordinator(
                rootViewController: controller,
                connectionType: .deepLink(url)
            )
            connectViewCoordinator?.start()
        }
    }
}

// MARK: - SetupAppDelegate
extension ApplicationCoordinator: SetupAppDelegate {
    func receivedQrMetadata(data: String) {
        startAuthorizationsViewController()

        guard let url = URL(string: data),
            SEConnectHelper.isValid(deepLinkUrl: url) else { return }

        startConnect(url: url, controller: authorizationsCoordinator.rootViewController)
    }

    func dismiss() {
        startAuthorizationsViewController()
    }
}
