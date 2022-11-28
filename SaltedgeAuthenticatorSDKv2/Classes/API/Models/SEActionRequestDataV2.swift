//
//  SEActionRequestDataV2
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
import SEAuthenticatorCore

public class SEActionRequestDataV2: SEBaseAuthenticatedRequestData {
    public let providerId: String
    public let actionId: String
    public let connectionId: String

    public init(
        url: URL,
        connectionGuid: GUID,
        accessToken: AccessToken,
        appLanguage: ApplicationLanguage,
        providerId: String,
        actionId: String,
        connectionId: String
    ) {
        self.providerId = providerId
        self.actionId = actionId
        self.connectionId = connectionId
        super.init(
            url: url,
            connectionGuid: connectionGuid,
            accessToken: accessToken,
            appLanguage: appLanguage
        )
    }
}
