//
//  AuthorizationsViewModel
//  This file is part of the Salt Edge Authenticator distribution
//  (https://github.com/saltedge/sca-authenticator-ios)
//  Copyright © 2020 Salt Edge Inc.
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

enum AuthorizationsViewModelState: Equatable {
    case changedConnectionsData
    case reloadData
    case scrollTo(Int)
    case presentFail(String)
    case scanQrPressed(Bool)
    case normal
    case requestLocationWarning

    static func == (lhs: AuthorizationsViewModelState, rhs: AuthorizationsViewModelState) -> Bool {
        switch (lhs, rhs) {
        case (.changedConnectionsData, .changedConnectionsData),
             (.reloadData, .reloadData), (.normal, .normal),
             (.requestLocationWarning, .requestLocationWarning): return true
        case let (.scrollTo(index1), .scrollTo(index2)): return index1 == index2
        case let (.presentFail(message1), .presentFail(message2)): return message1 == message2
        case let (.scanQrPressed(value1), .scanQrPressed(value2)): return value1 == value2
        default: return false
        }
    }
}

final class AuthorizationsViewModel {
    private struct Images {
        static let noAuthorizations: UIImage = UIImage(named: "noAuthorizations", in: .authenticator_main, compatibleWith: nil)!
        static let noConnections: UIImage = UIImage(named: "noConnections", in: .authenticator_main, compatibleWith: nil)!
    }

    var state = Observable<AuthorizationsViewModelState>(.normal)

    var dataSource: AuthorizationsDataSource!
    private var connectionsListener: RealmConnectionsListener?

    private var poller: SEPoller? // TODO: Think about moving poller to interactor
    private var connections = ConnectionsCollector.activeConnections

    var singleAuthorization: (connectionId: String, authorizationId: String)? {
        willSet {
            setupPolling()
        }
        didSet {
            getEncryptedAuthorizationsIfAvailable()
        }
    }

    init() {
        connectionsListener = RealmConnectionsListener(
            onDataChange: {
                self.state.value = .changedConnectionsData
            }
        )
        setupPollingObservers()
    }

    deinit {
        NotificationsHelper.removeObserver(self)
        stopPolling()
    }

    func resetState() {
        state.value = .normal
    }

    var emptyViewData: EmptyViewData {
        if dataSource.hasConnections {
            return EmptyViewData(
                image: Images.noAuthorizations,
                title: l10n(.noAuthorizations),
                description: l10n(.noAuthorizationsDescription),
                buttonTitle: l10n(.scanQr)
            )
        } else {
            return EmptyViewData(
                image: Images.noConnections,
                title: l10n(.noConnections),
                description: l10n(.noConnectionsDescription),
                buttonTitle: l10n(.connect)
            )
        }
    }

    func confirmAuthorization(by authorizationId: String, apiVersion: ApiVersion) {
        guard let data = dataSource.confirmationData(for: authorizationId, apiVersion: apiVersion),
            let detailViewModel = dataSource.viewModel(with: authorizationId, apiVersion: apiVersion) else { return }

        if detailViewModel.shouldShowLocationWarning {
            state.value = .requestLocationWarning
        } else {
            detailViewModel.state.value = .processing

            AuthorizationsInteractor.confirm(
                apiVersion: detailViewModel.apiVersion,
                data: data,
                successV1: {
                    detailViewModel.setFinal(status: .confirmed)
                },
                successV2: { response in
                    if response.status.isFinal {
                        detailViewModel.setFinal(status: .confirmed)
                    }
                },
                failure: { _ in
                    detailViewModel.setFinal(status: .error)
                }
            )
        }
    }

    func denyAuthorization(by authorizationId: String, apiVersion: ApiVersion) {
        guard let data = dataSource.confirmationData(for: authorizationId, apiVersion: apiVersion),
            let detailViewModel = dataSource.viewModel(with: authorizationId, apiVersion: apiVersion) else { return }

        if detailViewModel.shouldShowLocationWarning {
            state.value = .requestLocationWarning
        } else {
            detailViewModel.state.value = .processing

            AuthorizationsInteractor.deny(
                apiVersion: detailViewModel.apiVersion,
                data: data,
                successV1: {
                    detailViewModel.setFinal(status: .denied)
                },
                successV2: { response in
                    if response.status.isFinal {
                        detailViewModel.setFinal(status: .denied)
                    }
                },
                failure: { _ in
                    detailViewModel.setFinal(status: .error)
                }
            )
        }
    }

    private func updateDataSource(with authorizations: [SEBaseAuthorizationData]) {
        if dataSource.update(with: authorizations) {
            state.value = .reloadData
        }

        scrollToSingleAuthorization()
    }

    private func scrollToSingleAuthorization() {
        if let authorizationToScroll = singleAuthorization {
            if let detailViewModel = dataSource.viewModel(
                by: authorizationToScroll.connectionId,
                authorizationId: authorizationToScroll.authorizationId
            ),
            let index = dataSource.index(of: detailViewModel) {
                state.value = .scrollTo(index)
            } else {
                state.value = .presentFail(l10n(.authorizationNotFound))
            }
            singleAuthorization = nil
        }
    }
}

// MARK: - Polling
extension AuthorizationsViewModel {
    func setupPolling() {
        if poller == nil {
            poller = SEPoller(targetClass: self, selector: #selector(getEncryptedAuthorizationsIfAvailable))
            getEncryptedAuthorizationsIfAvailable()
            poller?.startPolling()
        }
    }

    func stopPolling() {
        poller?.stopPolling()
        poller = nil
        dataSource.clearAuthorizations()
        state.value = .reloadData
    }

    private func setupPollingObservers() {
        NotificationsHelper.observe(
            self,
            selector: #selector(appMovedToForeground),
            name: UIApplication.willEnterForegroundNotification
        )
        NotificationsHelper.observe(
            self,
            selector: #selector(appMovedToBackground),
            name: UIApplication.didEnterBackgroundNotification
        )
    }

    @objc private func appMovedToBackground() {
        if let navVc = UIApplication.appDelegate.window?.rootViewController as? UINavigationController,
            navVc.viewControllers.last as? AuthorizationsViewController != nil {
            stopPolling()
        }
    }

   @objc private func appMovedToForeground() {
       if let navVc = UIApplication.appDelegate.window?.rootViewController as? UINavigationController,
           navVc.viewControllers.last as? AuthorizationsViewController != nil {
           setupPolling()
       }
   }
}

// MARK: - Actions
extension AuthorizationsViewModel {
    func scanQrPressed() {
        AVCaptureHelper.requestAccess(
            success: {
                self.state.value = .scanQrPressed(true)
            },
            failure: {
                self.state.value = .scanQrPressed(false)
            }
        )
    }
}

// MARK: - Data Source
extension AuthorizationsViewModel {
    var hasDataToShow: Bool {
        return dataSource.hasDataToShow
    }

    var numberOfRows: Int {
        return dataSource.rows
    }

    var numberOfSections: Int {
        return dataSource.sections
    }

    func detailViewModel(at index: Int) -> AuthorizationDetailViewModel? {
        return dataSource.viewModel(at: index)
    }
}

// MARK: - Networking
private extension AuthorizationsViewModel {
    @objc func getEncryptedAuthorizationsIfAvailable() {
        if poller != nil, connections.count > 0 {
            refresh()
        } else {
            updateDataSource(with: [])
        }
    }

    @objc func refresh() {
        CollectionsInteractor.authorizations.refresh(
            connections: Array(connections),
            success: { [weak self] encryptedAuthorizations in
                guard let strongSelf = self else { return }

                DispatchQueue.global(qos: .background).async {
                    let decryptedAuthorizationsV1 = encryptedAuthorizations.compactMap { $0.decryptedAuthorizationData }
                    let decryptedAuthorizationsV2 = encryptedAuthorizations.compactMap { $0.decryptedAuthorizationDataV2 }

                    DispatchQueue.main.async {
                        strongSelf.updateDataSource(with: decryptedAuthorizationsV1 + decryptedAuthorizationsV2)
                    }
                }
            },
            failure: { error in
                Log.debugLog(message: error)
            },
            connectionNotFoundFailure: { connectionId in
                if let id = connectionId, let connection = ConnectionsCollector.with(id: id) {
                    ConnectionRepository.setInactive(connection)
                }
            }
        )
    }
}
