//
//  AuthorizationHeaderView
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

private struct Layout {
    static let connectionImageViewSize: CGSize = CGSize(width: 28.0, height: 28.0)
    static let connectionImageViewOffset: CGFloat = 8.0
    static let nameLabelLeftOffset: CGFloat = 6.0
    static let nameLabelRightOffset: CGFloat = 4.0
    static let progressViewWidthOffset: CGFloat = -22.0
    static let timeLeftLabelOffset: CGFloat = -10.0
    static let timeLeftLabelHeight: CGFloat = 28.0
    static let imagePlaceholderViewRadius: CGFloat = 6.0
}

final class AuthorizationHeaderView: RoundedShadowView {
    private let logoPlaceholderView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = Layout.imagePlaceholderViewRadius
        view.clipsToBounds = true
        view.backgroundColor = .extraLightGray
        return view
    }()
    private let connectionImageView = AspectFitImageView(imageName: "")
    private let connectionNameLabel = UILabel(font: .systemFont(ofSize: 14.0), textColor: .titleColor)
    private let timeLeftLabel = TimeLeftLabel()
    private let progressView = CountdownProgressView()

    var viewModel: AuthorizationDetailViewModel! {
        didSet {
            if let connection = ConnectionsCollector.with(id: viewModel.connectionId) {
                setImage(from: connection.logoUrl)
                connectionNameLabel.text = connection.name
            }
            updateTime()
        }
    }

    init() {
        super.init(cornerRadius: 4.0)
        timeLeftLabel.completion = {
            self.viewModel.authorizationExpired = true
        }
        layout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateTime() {
        guard viewModel.state.value == .base, viewModel.actionTime == nil else { return }

        let secondsLeft = diffInSecondsFromNow(for: viewModel.authorizationExpiresAt)

        progressView.update(secondsLeft: secondsLeft, lifetime: viewModel.lifetime)
        timeLeftLabel.update(secondsLeft: secondsLeft)
    }
}

// MARK: - Helpers
private extension AuthorizationHeaderView {
    func setupShadowAndCornerRadius() {
        connectionImageView.layer.masksToBounds = true
        connectionImageView.layer.cornerRadius = 6.0
    }

    func setImage(from imageUrl: URL?) {
        guard let url = imageUrl else { return }

        CacheHelper.setAnimatedCachedImage(from: url, for: connectionImageView)
    }
}

// MARK: - Layout
extension AuthorizationHeaderView: Layoutable {
    func layout() {
        addSubviews(logoPlaceholderView, connectionNameLabel, progressView, timeLeftLabel)
        logoPlaceholderView.addSubview(connectionImageView)

        logoPlaceholderView.size(Layout.connectionImageViewSize)
        logoPlaceholderView.left(to: self, offset: Layout.connectionImageViewOffset)
        logoPlaceholderView.centerY(to: self)

        connectionImageView.center(in: logoPlaceholderView)
        connectionImageView.size(Layout.connectionImageViewSize)

        connectionNameLabel.leftToRight(of: connectionImageView, offset: Layout.nameLabelLeftOffset)
        connectionNameLabel.centerY(to: connectionImageView)
        connectionNameLabel.rightToLeft(of: timeLeftLabel, offset: -Layout.nameLabelRightOffset, relation: .equalOrLess)
        connectionNameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        progressView.height(3.0)
        progressView.bottom(to: self)
        progressView.width(to: self)
        progressView.centerX(to: self)

        timeLeftLabel.right(to: self, offset: Layout.timeLeftLabelOffset)
        timeLeftLabel.centerY(to: connectionImageView)
        timeLeftLabel.height(Layout.timeLeftLabelHeight)
        timeLeftLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
    }
}

private extension AuthorizationHeaderView {
    func diffInSecondsFromNow(for date: Date) -> Int {
        let currentDate = Date()
        let diffDateComponents = Calendar.current.dateComponents([.minute, .second], from: currentDate, to: date)

        guard let minutes = diffDateComponents.minute, let seconds = diffDateComponents.second else { return 0 }

        return 60 * minutes + seconds
    }
}
