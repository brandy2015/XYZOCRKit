//
//  ActivityToken.swift
//  XYZOCRAli
//
//  Created by 张子豪 on 2025/7/16.
//


import Foundation
import RxSwift
import RxCocoa

private struct ActivityToken<E>: ObservableConvertibleType, Disposable {
    private let source: Observable<E>
    private let cancellation: Cancelable

    init(source: Observable<E>, disposeAction: @escaping () -> Void) {
        self.source = source
        self.cancellation = Disposables.create(with: disposeAction)
    }

    func dispose() {
        cancellation.dispose()
    }

    func asObservable() -> Observable<E> {
        return source
    }
}

public class ActivityIndicator: SharedSequenceConvertibleType {
    public typealias Element = Bool
    public typealias SharingStrategy = DriverSharingStrategy

    private let lock = NSRecursiveLock()
    private let relay = BehaviorRelay(value: 0)
    private let loading: SharedSequence<SharingStrategy, Bool>

    public init() {
        loading = relay
            .asDriver()
            .map { $0 > 0 }
            .distinctUntilChanged()
    }

    fileprivate func trackActivityOfObservable<O: ObservableConvertibleType>(_ source: O) -> Observable<O.Element> {
        return Observable.using({ () -> ActivityToken<O.Element> in
            self.increment()
            return ActivityToken(source: source.asObservable(), disposeAction: self.decrement)
        }) { t in
            return t.asObservable()
        }
    }

    private func increment() {
        lock.lock()
        relay.accept(relay.value + 1)
        lock.unlock()
    }

    private func decrement() {
        lock.lock()
        relay.accept(relay.value - 1)
        lock.unlock()
    }

    public func asSharedSequence() -> SharedSequence<SharingStrategy, Element> {
        return loading
    }
}

public extension ObservableConvertibleType {
    func trackActivity(_ activityIndicator: ActivityIndicator) -> Observable<Element> {
        return activityIndicator.trackActivityOfObservable(self)
    }
}
