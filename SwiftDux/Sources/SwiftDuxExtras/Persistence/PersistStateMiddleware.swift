import Combine
import Foundation
import SwiftDux

#if canImport(UIKit)

  import UIKit
  fileprivate let notification: NSNotification.Name? = UIApplication.didEnterBackgroundNotification

#elseif canImport(AppKit)

  import AppKit
  fileprivate let notification: NSNotification.Name? = NSApplication.willResignActiveNotification

#else

  fileprivate let notification: NSNotification.Name? = nil

#endif

/// Hooks up state peristence to the store.
public final class PersistStateMiddleware<State, SP>: TypedMiddleware<State> where SP: StatePersistor, SP.State == State {
  private var persistor: SP
  private var saveOnChange: Bool
  private var interval: RunLoop.SchedulerTimeType.Stride
  private var shouldRestore: (State) -> Bool
  private var subscriptionCancellable: AnyCancellable?

  // swift-format-disable: ValidateDocumentationComments

  /// - Parameters:
  ///   - persistor: The state persistor to use.
  ///   - saveOnChange: Saves the state when it changes, else, it saves when the app enters the backgroound.
  ///   - interval: The debounce interval for saving on changes.
  ///   - shouldRestore: Closure used to validate the state before restoring it. This is useful if the state's schema version has changed.
  public init(
    _ persistor: SP,
    saveOnChange: Bool = true,
    debounceFor interval: RunLoop.SchedulerTimeType.Stride = .seconds(1),
    shouldRestore: @escaping (State) -> Bool = { _ in true }
  ) {
    self.persistor = persistor
    self.saveOnChange = saveOnChange
    self.interval = interval
    self.shouldRestore = shouldRestore
    super.init()
  }

  public override func run(store: StoreProxy<State>, action: Action) {
    defer { store.next(action) }
    guard case .prepare = action as? StoreAction<State> else { return }

    if saveOnChange {
      subscriptionCancellable = persistor.save(from: store, debounceFor: interval)
    } else if let notification = notification {
      subscriptionCancellable = NotificationCenter.default
        .publisher(for: notification)
        .debounce(for: interval, scheduler: RunLoop.main)
        .compactMap { _ in store.state }
        .persist(with: persistor)
    } else {
      print("Failed to initiate persistence using notifiation.")
    }

    if let state = persistor.restore(), shouldRestore(state) {
      store.send(StoreAction<State>.reset(state: state))
    }
  }
}
