//
//  CacheHelper
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
import Kingfisher
import SVGKit

struct CacheHelper {
    enum CachedImageType: String {
        case photo
        case svg
    }

    static var cache = ImageCache.default
    private static let placeholderImage = UIImage(named: "bankPlaceholderCyan")

    static func isImageCached(for url: URL) -> Bool {
        return cache.isCached(forKey: url.absoluteString)
    }

    static func remove(for url: URL) {
        cache.removeImage(forKey: url.absoluteString)
    }

    static func setImage(for url: URL?, imageView: UIImageView) {
        guard let url = url else {
            imageView.image = placeholderImage
            return
        }

        if isImageCached(for: url) {
            getImage(for: url, imageView: imageView)
        } else {
            cache(for: url, imageView: imageView)
        }
    }

    static func cache(
        for url: URL,
        imageView: UIImageView
    ) {
        imageView.kf.setImage(
            with: url,
            placeholder: placeholderImage,
            options: url.pathExtension == CachedImageType.svg.rawValue ? [.processor(SVGImgProcessor())] : nil
        )
    }

    static func getImage(for url: URL, imageView: UIImageView) {
        imageView.image = placeholderImage

        guard isImageCached(for: url) else { return }

        cache.retrieveImage(
            forKey: url.absoluteString,
            options: url.pathExtension == CachedImageType.svg.rawValue ? [.processor(SVGImgProcessor())] : nil
        ) { result in
            switch result {
            case .success(let value): imageView.image = value.image
            case .failure: imageView.image = placeholderImage
            }
        }
    }

    static func store(for url: URL) {
        guard !isImageCached(for: url), let data = try? Data(contentsOf: url) else { return }

        cache.storeToDisk(data, forKey: url.absoluteString)
    }

    static func remove(for url: URL?) {
        guard let logoUrl = url else { return }

        cache.removeImage(forKey: logoUrl.absoluteString)
    }

    static func setDefaultDiskAge() {
        cache.diskStorage.config.expiration = .seconds(3600 * 24 * 7) // NOTE: One week
    }

    static func clearCache() {
        cache.clearCache()
    }
}

private struct SVGImgProcessor: ImageProcessor {
    var identifier: String = "com.authenticator.svgimageprocessor"

    func process(item: ImageProcessItem, options: KingfisherParsedOptionsInfo) -> KFCrossPlatformImage? {
        switch item {
        case .image(let image):
            return image
        case .data(let data):
            return SVGKImage(data: data)?.uiImage
        }
    }
}
