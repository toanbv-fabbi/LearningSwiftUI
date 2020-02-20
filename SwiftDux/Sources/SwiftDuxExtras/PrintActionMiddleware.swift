import Foundation
import SwiftDux

/// Default printer for the `PrintActionMiddleware<_>`
fileprivate func defaultActionPrinter(_ actionDescription: String) {
  print(actionDescription)
}

/// A simple middlware that prints the description of the latest action.
public final class PrintActionMiddleware: Middleware {
  public var printer: ((String) -> Void) = defaultActionPrinter
  public var filter: (Action) -> Bool = { _ in true }

  // swift-format-disable: ValidateDocumentationComments

  /// - Parameters:
  ///   - printer: A custom printer for the action's discription. Defaults to print().
  ///   - filter: Filter what actions get printed.
  public init(printer: ((String) -> Void)? = nil, filter: @escaping (Action) -> Bool = { _ in true }) {
    self.printer = printer ?? defaultActionPrinter
    self.filter = filter
  }

  public func run<State>(store: StoreProxy<State>, action: Action) where State: StateType {
    defer { store.next(action) }
    guard filter(action) else { return }
    printer(String(describing: action))
  }
}
