//
//  AuthorizationsHeaderCollectionViewCell
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

struct AuthorizationCellViewModel {
    let name: String
    let expiresAt: Date
    let lifetime: Int
    let logoUrl: URL?
    let completionBlock: (() -> ())?
}

private struct Layout {
    static let connectionImageViewSize: CGSize = CGSize(width: 24.0, height: 24.0)
    static let connectionImageViewOffset: CGFloat = 16.0
    static let nameLabelOffset: CGFloat = 8.0
    static let progressViewWidthOffset: CGFloat = -22.0
    static let timeLeftLabelOffset: CGFloat = -8.0
    static let timeLeftLabelHeight: CGFloat = 28.0
}

final class AuthorizationHeaderCollectionViewCell: UICollectionViewCell {
    private let containerView = UIView()
    private let connectionImageView = UIImageView()
    private let connectionNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14.0, weight: .medium)
        return label
    }()
    private let timeLeftLabel = TimeLeftLabel()
    private let progressView = CountdownProgressView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        containerView.backgroundColor = .white
        setupShadowAndCornerRadius()
        layout()
    }

    func configure(_ item: AuthorizationViewModel, at indexPath: IndexPath) {
        connectionImageView.contentMode = .scaleAspectFit
        connectionImageView.image = #imageLiteral(resourceName: "bankPlaceholderCyanSmall")

        if let connection = ConnectionsCollector.with(id: item.connectionId) {
            setImage(from: connection.logoUrl)
            connectionNameLabel.text = connection.name
        }
        timeLeftLabel.update(secondsLeft: diffInSecondsFromNow(for: item.authorizationExpiresAt))
        progressView.update(
            secondsLeft: diffInSecondsFromNow(for: item.authorizationExpiresAt),
            lifetime: item.lifetime
        )
    }

    private func setupShadowAndCornerRadius() {
        containerView.layer.cornerRadius = 21.0
        containerView.layer.masksToBounds = true
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 0)
        layer.shadowOpacity = 0.1
        layer.shadowRadius = 4.0
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setImage(from imageUrl: URL?) {
        guard let url = imageUrl else { return }

        ConnectionImageHelper.setAnimatedCachedImage(from: url, for: connectionImageView)
    }
}

extension AuthorizationHeaderCollectionViewCell: Layoutable {
    func layout() {
        contentView.addSubview(containerView)

        containerView.addSubviews(connectionImageView, connectionNameLabel, progressView, timeLeftLabel)

        containerView.edgesToSuperview()

        connectionImageView.left(to: containerView, offset: Layout.connectionImageViewOffset)
        connectionImageView.centerY(to: containerView)
        connectionImageView.size(Layout.connectionImageViewSize)

        connectionNameLabel.leftToRight(of: connectionImageView, offset: Layout.nameLabelOffset)
        connectionNameLabel.centerY(to: connectionImageView)

        progressView.height(3.0)
        progressView.bottom(to: containerView)
        progressView.width(to: containerView, offset: Layout.progressViewWidthOffset)
        progressView.centerX(to: containerView)

        timeLeftLabel.right(to: containerView, offset: Layout.timeLeftLabelOffset)
        timeLeftLabel.centerY(to: connectionImageView)
        timeLeftLabel.height(Layout.timeLeftLabelHeight)
    }
}

private extension AuthorizationHeaderCollectionViewCell {
    func diffInSecondsFromNow(for date: Date) -> Int {
        let currentDate = Date()
        let diffDateComponents = Calendar.current.dateComponents([.minute, .second], from: currentDate, to: date)

        guard let minutes = diffDateComponents.minute, let seconds = diffDateComponents.second else { return 0 }

        return 60 * minutes + seconds
    }
}
