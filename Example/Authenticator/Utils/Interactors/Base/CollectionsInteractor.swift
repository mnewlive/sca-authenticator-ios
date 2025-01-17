//
//  CollectionsInteractor.swift
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
import SEAuthenticatorV2
import SEAuthenticatorCore

// TODO: Remade to on interator
enum CollectionsInteractor {
    case authorizations
    case consents

    func refresh(
        connection: Connection,
        success: @escaping ([SEBaseEncryptedAuthorizationData]) -> (),
        failure: ((String) -> ())? = nil,
        connectionNotFoundFailure: @escaping ((String?) -> ())
    ) {
        func onFailure(error: String, connection: Connection) {
            if SEAPIError.connectionNotFound.isConnectionNotFound(error) {
                connectionNotFoundFailure(connection.id)
            } else {
                failure?("\(l10n(.somethingWentWrong)) (\(connection.name))")
            }
        }

        guard let baseUrl = connection.baseUrl else { failure?(l10n(.somethingWentWrong)); return }

        let requestData = SEBaseAuthenticatedRequestData(
            url: baseUrl,
            connectionGuid: connection.guid,
            accessToken: connection.accessToken,
            appLanguage: UserDefaultsHelper.applicationLanguage
        )

        switch self {
        case .authorizations:
            if connection.isApiV2 {
                SEAuthorizationManagerV2.getEncryptedAuthorizations(
                    data: requestData,
                    onSuccess: { response in success(response.data) },
                    onFailure: { error in onFailure(error: error, connection: connection) }
                )
            } else {
                SEAuthorizationManager.getEncryptedAuthorizations(
                    data: requestData,
                    onSuccess: { response in success(response.data) },
                    onFailure: { error in onFailure(error: error, connection: connection) }
                )
            }
        case .consents:
            if connection.isApiV2 {
                SEConsentManagerV2.getEncryptedConsents(
                    data: requestData,
                    onSuccess: { response in success(response.data) },
                    onFailure: { error in onFailure(error: error, connection: connection) }
                )
            } else {
                SEConsentManager.getEncryptedConsents(
                    data: requestData,
                    onSuccess: { response in success(response.data) },
                    onFailure: { error in onFailure(error: error, connection: connection) }
                )
            }
        }
    }

    func refresh(
        connections: [Connection],
        success: @escaping ([SEBaseEncryptedAuthorizationData]) -> (),
        failure: ((String) -> ())? = nil,
        connectionNotFoundFailure: @escaping ((String?) -> ())
    ) {
        var encryptedAuthorizations = [SEBaseEncryptedAuthorizationData]()

        var numberOfResponses = 0

        func incrementAndCheckResponseCount() {
            numberOfResponses += 1

            if numberOfResponses == connections.count {
                success(encryptedAuthorizations)
            }
        }

        func onSuccess(data: [SEBaseEncryptedAuthorizationData]) {
            encryptedAuthorizations.append(contentsOf: data)

            incrementAndCheckResponseCount()
        }

        func onFailure(error: String, connection: Connection) {
            incrementAndCheckResponseCount()

            switch error {
            case SEAPIError.connectionNotFound.rawValue:
                connectionNotFoundFailure(connection.id)
            case SEAPIError.connectionAlreadyRevoked.rawValue:
                guard connection.isActive else { return }

                ConnectionRepository.setInactive(connection)
            default:
                failure?("\(l10n(.somethingWentWrong)) (\(connection.name))")
            }
        }

        for connection in connections {
            guard let baseUrl = connection.baseUrl else { failure?(l10n(.somethingWentWrong)); return }

            let requestData = SEBaseAuthenticatedRequestData(
                url: baseUrl,
                connectionGuid: connection.guid,
                accessToken: connection.accessToken,
                appLanguage: UserDefaultsHelper.applicationLanguage
            )

            switch self {
            case .authorizations:
                if connection.isApiV2 {
                    SEAuthorizationManagerV2.getEncryptedAuthorizations(
                        data: requestData,
                        onSuccess: { response in onSuccess(data: response.data) },
                        onFailure: { error in onFailure(error: error, connection: connection) }
                    )
                } else {
                    SEAuthorizationManager.getEncryptedAuthorizations(
                        data: requestData,
                        onSuccess: { response in onSuccess(data: response.data) },
                        onFailure: { error in onFailure(error: error, connection: connection) }
                    )
                }
            case .consents:
                if connection.isApiV2 {
                    SEConsentManagerV2.getEncryptedConsents(
                        data: requestData,
                        onSuccess: { response in
                            onSuccess(data: response.data)
                        }, onFailure: { error in
                            onFailure(error: error, connection: connection)
                        }
                    )
                } else {
                    SEConsentManager.getEncryptedConsents(
                        data: requestData,
                        onSuccess: { response in
                            onSuccess(data: response.data)
                        },
                        onFailure: { error in
                            onFailure(error: error, connection: connection)
                        }
                    )
                }
            }
        }
    }
}
