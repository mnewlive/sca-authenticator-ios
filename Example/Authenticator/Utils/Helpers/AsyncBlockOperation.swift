//
//  AsyncBlockOperation
//  This file is part of the Salt Edge Authenticator distribution
//  (https://github.com/saltedge/sca-authenticator-ios)
//  Copyright © 2022 Salt Edge Inc.
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

final class AsyncBlockOperation: Operation {
    override var isAsynchronous: Bool {
        true
    }

    override private(set) var isExecuting: Bool {
        get {
            lockQueue.sync {
                _isExecuting
            }
        }
        set {
            willChangeValue(forKey: "isExecuting")
            lockQueue.sync(flags: .barrier) {
                _isExecuting = newValue
            }
            didChangeValue(forKey: "isExecuting")
        }
    }

    override private(set) var isFinished: Bool {
        get {
            lockQueue.sync {
                _isFinished
            }
        }
        set {
            willChangeValue(forKey: "isFinished")
            lockQueue.sync(flags: .barrier) {
                _isFinished = newValue
            }
            didChangeValue(forKey: "isFinished")
        }
    }

    override private(set) var isCancelled: Bool {
        get {
            lockQueue.sync {
                _isCancelled
            }
        }
        set {
            willChangeValue(forKey: "isCancelled")
            lockQueue.sync(flags: .barrier) {
                _isCancelled = newValue
            }
            didChangeValue(forKey: "isCancelled")
        }
    }

    private var _isExecuting: Bool = false
    private var _isFinished: Bool = false
    private var _isCancelled: Bool = false
    private let lockQueue = DispatchQueue(
        label: "AsyncBlockOperation.lockQueue",
        attributes: .concurrent
    )

    private let queue: DispatchQueue?
    private let block: (@escaping AsyncBlockOperationCompletion) -> Void

    typealias AsyncBlockOperationCompletion = () -> Void

    init(on queue: DispatchQueue? = nil,
         block: @escaping (@escaping AsyncBlockOperationCompletion) -> Void) {
        self.block = block
        self.queue = queue
    }

    override func start() {
        isFinished = false
        isExecuting = true
        main()
    }

    override func main() {
        guard !isCancelled else {
            finish()
            return
        }

        if let queue = queue {
            queue.async {
                self.block { [weak self] in
                    self?.finish()
                }
            }
        } else {
            block { [weak self] in
                self?.finish()
            }
        }
    }

    func finish() {
        isExecuting = false
        isFinished = true
    }
}
