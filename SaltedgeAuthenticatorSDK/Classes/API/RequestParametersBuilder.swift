//
//  RequestParametersBuilder.swift
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

import Foundation
import SEAuthenticatorCore

struct ParametersKeys {
    static let data = "data"
    static let providerCode = "provider_code"
    static let publicKey = "public_key"
    static let deviceInfo = "device_info"
    static let platform = "platform"
    static let pushToken = "push_token"
    static let returnUrl = "return_url"
    static let connectQuery = "connect_query"
    static let confirm = "confirm"
    static let authorizationCode = "authorization_code"
    static let credentials = "credentials"
}

struct RequestParametersBuilder {
    static func parameters(for connectionData: SECreateConnectionRequestData, pushToken: PushToken, connectQuery: String?) -> [String: Any] {
        return [
            ParametersKeys.data: [
                ParametersKeys.providerCode: connectionData.providerCode,
                ParametersKeys.publicKey: connectionData.publicKey,
                ParametersKeys.returnUrl: SENetConstants.oauthRedirectUrl,
                ParametersKeys.platform: "ios",
                ParametersKeys.pushToken: pushToken,
                ParametersKeys.connectQuery: connectQuery
            ]
        ]
    }

    static func confirmAuthorization(_ confirm: Bool, authorizationCode: String?) -> [String: Any] {
        var data: [String: Any] = [ParametersKeys.confirm: confirm]

        if let authorizationCode = authorizationCode {
            data = data.merge(with: [ParametersKeys.authorizationCode: authorizationCode])
        }

        return [ParametersKeys.data: data]
    }
}
