//
//  SEConnectionManager.swift
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

public struct SEConnectionManager {
    public static func createConnection(
        by url: URL,
        data: SECreateConnectionRequestData,
        pushToken: PushToken,
        connectQuery: ConnectQuery? = nil,
        appLanguage: ApplicationLanguage,
        onSuccess success: SEHTTPResponse<SECreateConnectionResponse>,
        onFailure failure: @escaping FailureBlock
    ) {
        HTTPService<SECreateConnectionResponse>.makeRequest(
            SEConnectionRouter.createConnection(url, data, pushToken, connectQuery, appLanguage),
            completion: success,
            failure: failure
        )
    }

    public static func revokeConnection(
        data: SEBaseAuthenticatedWithIdRequestData,
        onSuccess success: SEHTTPResponse<SERevokeConnectionResponse>,
        onFailure failure: @escaping FailureBlock
    ) {
        HTTPService<SERevokeConnectionResponse>.makeRequest(
            SEConnectionRouter.revoke(data),
            completion: success,
            failure: failure
        )
    }
}
