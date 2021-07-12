//
//  SingleAuthorizationViewModel
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

import Foundation
import SEAuthenticator
import SEAuthenticatorCore

protocol SingleAuthorizationViewModelEventsDelegate: class {
    func receivedDetailViewModel(_ detailViewModel: AuthorizationDetailViewModel)
    func shouldClose()
}

final class SingleAuthorizationViewModel {
    private var connection: Connection?
    private var detailViewModel: AuthorizationDetailViewModel?

    weak var delegate: SingleAuthorizationViewModelEventsDelegate?

    init(connectionId: String, authorizationId: String, locationManagement: LocationManagement) {
        guard let connection = ConnectionsCollector.with(id: connectionId) else { return }

        self.connection = connection
        getAuthorization(
            connection: connection,
            authorizationId: authorizationId,
            showLocationWarning: locationManagement.shouldShowLocationWarning(connection: connection)
        )
    }

    private func getAuthorization(connection: Connection, authorizationId: String, showLocationWarning: Bool) {
        AuthorizationsInteractor.refresh(
            connection: connection,
            authorizationId: authorizationId,
            success: { [weak self] encryptedAuthorization in
                guard let strongSelf = self else { return }

                var decryptedAuthorizationData: SEBaseAuthorizationData?

                if connection.isApiV2 {
                    decryptedAuthorizationData = encryptedAuthorization.decryptedAuthorizationDataV2
                } else {
                    decryptedAuthorizationData = encryptedAuthorization.decryptedAuthorizationData
                }

                guard let data = decryptedAuthorizationData else { return }

                DispatchQueue.main.async {
                    if let viewModel = AuthorizationDetailViewModel(data, apiVersion: connection.apiVersion) {
                        strongSelf.detailViewModel = viewModel
                        strongSelf.detailViewModel?.delegate = self

                        strongSelf.delegate?.receivedDetailViewModel(viewModel)
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

// MARK: - AuthorizationDetailEventsDelegate
extension SingleAuthorizationViewModel: AuthorizationDetailEventsDelegate {
    func confirmPressed(_ authorizationId: String, apiVersion: ApiVersion) {
        guard let detailViewModel = detailViewModel, let connection = connection, let url = connection.baseUrl else { return }

        let confirmData = SEConfirmAuthorizationRequestData(
            url: url,
            connectionGuid: connection.guid,
            accessToken: connection.accessToken,
            appLanguage: UserDefaultsHelper.applicationLanguage,
            authorizationId: authorizationId,
            authorizationCode: detailViewModel.authorizationCode,
            geolocation: LocationManager.currentLocation?.headerValue,
            authorizationType: PasscodeCoordinator.lastAppUnlockCompleteType.rawValue
        )

        detailViewModel.state.value = .processing

        AuthorizationsInteractor.confirm(
            apiVersion: detailViewModel.apiVersion,
            data: confirmData,
            successV1: {
                self.updateDetailViewModel(state: .confirmed)
            },
            successV2: { response in
                if response.status.isFinal {
                    self.updateDetailViewModel(state: .confirmed)
                }
            },
            failure: { _ in
                self.updateDetailViewModel(state: .error)
            }
        )
    }

    func denyPressed(_ authorizationId: String, apiVersion: ApiVersion) {
        guard let detailViewModel = detailViewModel, let connection = connection, let url = connection.baseUrl else { return }

        let confirmData = SEConfirmAuthorizationRequestData(
            url: url,
            connectionGuid: connection.guid,
            accessToken: connection.accessToken,
            appLanguage: UserDefaultsHelper.applicationLanguage,
            authorizationId: authorizationId,
            authorizationCode: detailViewModel.authorizationCode,
            geolocation: LocationManager.currentLocation?.headerValue,
            authorizationType: PasscodeCoordinator.lastAppUnlockCompleteType.rawValue
        )

        detailViewModel.state.value = .processing

        AuthorizationsInteractor.deny(
            apiVersion: detailViewModel.apiVersion,
            data: confirmData,
            successV1: {
                self.updateDetailViewModel(state: .denied)
            },
            successV2: { response in
                if response.status.isFinal {
                    self.updateDetailViewModel(state: .denied)
                }
            },
            failure: { _ in
                self.updateDetailViewModel(state: .error)
            }
        )
    }

    func authorizationExpired() {
        detailViewModel?.state.value = .timeOut
        after(finalAuthorizationTimeToLive) {
            self.delegate?.shouldClose()
        }
    }

    private func updateDetailViewModel(state: AuthorizationStateView.AuthorizationState) {
        detailViewModel?.state.value = state
        detailViewModel?.actionTime = Date()
        after(finalAuthorizationTimeToLive) {
            self.delegate?.shouldClose()
        }
    }
}
