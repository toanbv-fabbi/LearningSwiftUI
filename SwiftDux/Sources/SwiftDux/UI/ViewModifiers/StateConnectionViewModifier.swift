import Combine
import SwiftUI

/// Indicates a connectable view should not update when the state changes. The view will not subscribe to the store, and instead update
/// only when it dispatches an action.
internal final class NoUpdateAction: Action {
  var unused: Bool = false
}

internal struct StateConnectionViewModifier<Superstate, State>: ViewModifier where Superstate: Equatable, State: Equatable {
  @EnvironmentObject private var superstateConnection: StateConnection<Superstate>
  @Environment(\.storeUpdated) private var storeUpdated
  @Environment(\.actionDispatcher) private var actionDispatcher

  private var filter: ((Action) -> Bool)?
  private var mapState: (Superstate, StateBinder) -> State?

  internal init(filter: ((Action) -> Bool)?, mapState: @escaping (Superstate, StateBinder) -> State?) {
    self.mapState = mapState
  }

  func body(content: Content) -> some View {
    let stateConnection = superstateConnection.map(
      state: mapState,
      changePublisher: createChangePublisher(),
      binder: StateBinder(
        actionDispatcher: actionDispatcher
      )
    )
    return stateConnection.state.map { _ in
      content.environmentObject(stateConnection)
    }
  }

  private func createChangePublisher() -> AnyPublisher<Action, Never> {
    guard let filter = filter, hasUpdateFilter() else {
      return storeUpdated
    }
    return storeUpdated.filter(filter).eraseToAnyPublisher()
  }

  private func hasUpdateFilter() -> Bool {
    let noUpdateAction = NoUpdateAction()
    _ = filter?(noUpdateAction)
    return !noUpdateAction.unused
  }

}

extension View {

  /// Connect the application state to the UI.
  ///
  /// The returned mapped state is provided to the environment and accessible through the `MappedState` property wrapper.
  /// - Parameters
  ///   - filter: Update the state when the closure returns true. If not provided, it will only update when dispatching an action.
  ///   - mapState: Maps a superstate to a substate.
  /// - Returns: The modified view.
  @available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
  public func connect<Superstate, State>(
    updateWhen filter: ((Action) -> Bool)? = nil,
    mapState: @escaping (Superstate, StateBinder) -> State?
  ) -> some View where Superstate: Equatable, State: Equatable {
    self.modifier(StateConnectionViewModifier(filter: filter, mapState: mapState))
  }

}
