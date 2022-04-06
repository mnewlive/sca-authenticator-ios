//
//  SEPollingTimer
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

public class SEPoller {
    private var timer: Timer?
    private var targetClass: Any
    @objc private var executionSelector: Selector

    public init(targetClass: Any, selector: Selector) {
        self.targetClass = targetClass
        self.executionSelector = selector
    }

    public func startPolling() {
        timer = Timer.scheduledTimer(
            timeInterval: 3.0,
            target: targetClass,
            selector: executionSelector,
            userInfo: nil,
            repeats: true
        )
    }

    public func stopPolling() {
        timer?.invalidate()
        timer = nil
    }
}

