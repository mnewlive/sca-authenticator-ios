//
//  SEConfirmAuthorizationData
//  This file is part of the Salt Edge Authenticator distribution
//  (https://github.com/saltedge/sca-authenticator-ios)
//  Copyright © 2021 Salt Edge Inc.
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

public class SEConfirmAuthorizationRequestData: SEBaseAuthenticatedWithIdRequestData {
    public let authorizationCode: String?

    // NOTE: Temporarily inactive due to legal restrictions
    // public let geolocation: String?
    // public let authorizationType: String

    public init(
        url: URL,
        connectionGuid: GUID,
        accessToken: AccessToken,
        appLanguage: ApplicationLanguage,
        authorizationId: ID,
        authorizationCode: String?
        // NOTE: Temporarily inactive due to legal restrictions
        // geolocation: String?,
        // authorizationType: String
    ) {
        self.authorizationCode = authorizationCode
        // NOTE: Temporarily inactive due to legal restrictions
        // self.geolocation = geolocation
        // self.authorizationType = authorizationType
        super.init(
            url: url,
            connectionGuid: connectionGuid,
            accessToken: accessToken,
            appLanguage: appLanguage,
            entityId: authorizationId
        )
    }
}
