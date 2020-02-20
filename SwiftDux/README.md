# SwiftDux

> Predictable state management for SwiftUI applications.

[![Swift Version][swift-image]][swift-url]
![Platform Versions][ios-image]
[![Github workflow][github-workflow-image]](https://github.com/StevenLambion/SwiftDux/actions)
[![codecov][codecov-image]](https://codecov.io/gh/StevenLambion/SwiftDux)

SwiftDux is a redux inspired state management solution built on top of Combine and SwiftUI. It presents a way to implement an elm or flux like architecture as an alternative to the MVVM-like patterns Apple has presented. It allows you to build an application around predictable state using reactive, unidirectional data flows.

## Should I use this?

SwiftDux relies on advance functionality of SwiftUI that may break or change between Xcode updates. Because of this, it is in constant development and should be considered a beta until SwiftUI has a more stable release. If you're starting a new application using SwiftUI that will be released with or after the next major OS, then it should be OK to use this library. If you need to target an older operating system or require a more established library,  check out [ReSwift](https://github.com/ReSwift/ReSwift) instead.

## Features

- Familiar API to __Redux__.
- Built for __SwiftUI__.
- __Middleware__ support
- __Combine__ powered __Action Plans__ to incapsulate async workflows.
- __OrderedState<_>__ to display sorted entities in List views.

## Built-in Middleware

- `PersistStateMiddleware` automatically persists and restores the application state.
- `PrintActionMiddleware` prints out each dispatched action for debugging purposes.

# Installation

## Prerequisites
- Xcode 11+
- Swift 5.1+
- iOS 13+, macOS 10.15+, tvOS 13+, or watchOS 6+

## Install via Xcode 11:

Search for SwiftDux in Xcode's Swift Package Manager integration.

## Install via the Swift Package Manager:

```swift
import PackageDescription

let package = Package(
  dependencies: [
    .Package(url: "https://github.com/StevenLambion/SwiftDux.git", majorVersion: 0, minor: 12)
  ]
)
```

# Demo Application

Take a look at the [Todo Example App](https://github.com/StevenLambion/SwiftUI-Todo-Example) to see how SwiftDux works.

# Getting Started

SwiftDux helps build SwiftUI-based applications around an [elm-like architecture](https://guide.elm-lang.org/architecture/) using a single, centralized state container. It has 4 basic principles:

- **State** - An immutable, single source of truth within the application.
- **Action** - Describes a single change of the state.
- **Reducer** - Returns a new state by consuming the previous one with an action.
- **View** - The visual representation of the current state.

<div style="text-align:center">
  <img src="Guides/Images/architecture.jpg" width="400"/>
</div>

## State

The state is a single, immutable structure acting as the single source of truth within the application.

Below is an example of a todo app's state. It has a root `AppState` as well as an ordered list of `TodoState` objects. When storing entities in state, the `IdentifiableState` protocol should be used to display them in a list.

```swift
import SwiftDux

struct AppState: StateTyoe {
  todos: OrderedState<TodoItem>
}

struct TodoItem: IdentifiableState {
  var id: String,
  var text: String
}
```

## Actions

An action is a description of how the state will change. They're typically dispatched from events in the application, such as a user clicking a button. Swift's enum type is ideal for actions, but structs and classes could be used if required.

```swift
import SwiftDux

enum TodoAction: Action {
  case addTodo(text: String)
  case removeTodos(at: IndexSet)
  case moveTodos(from: IndexSet, to: Int)
}
```

It can be useful to categorize actions through a shared protocol:

```swift
protocol SettingsAction: Action {}

enum GeneralSettingsAction: SettingsAction {
  ...
}

enum NetworkSettingsAction: SettingsAction {
  ...
}
```

## Reducers

A reducer consumes an action to produce a new state. There's always a root reducer that consumes all actions. From here, it can delegate out to sub-reducers. Each reducer conforms to a single type of action.

The `Reducer` protocol has two primary methods to override:

- `reduce(state:action:)` - For actions supported by the reducer.
- `reduceNext(state:action:)` - Dispatches an action to any sub-reducers. This method is optional.

```swift
final class TodosReducer: Reducer {

  func reduce(state: OrderedState<TodoItem>, action: TodoAction) -> OrderedState<TodoItem> {
    var state = state
    switch action {
    case .addTodo(let text):
      let id = UUID().uuidString
      state.append(TodoItemState(id: id, text: text))
    case .removeTodos(let indexSet):
      state.remove(at: indexSet)
    case .moveTodos(let indexSet, let index):
      state.move(from: indexSet, to: index)
    }
    return state
  }

}
```

```swift
final class AppReducer: Reducer {
  let todosReducer = TodosReducer()

  func reduceNext(state: AppState, action: TodoAction) -> AppState {
    State(
      todos: todosReducer.reduceAny(state.todos, action)
    )
  }

}
```

## Store

The store acts as the container of the state. Initialize the store with a default state and the root reducer. Then use the `provideStore(_:)` view modifier at the root of the application to inject the store into the environment.

```swift
import SwiftDux

let store = Store(AppState(todos: OrderedState()), AppReducer())

window.rootViewController = UIHostingController(
  rootView: RootView().provideStore(store)
)
```

## Connectable View

Use the `ConnectableView` protocol to inject the application state into your view. It provides a `map(state:)` and body(props:) functions to retrieve and map the state to a shape needed by the view. The `@MappedDispatch` property wrapper can be used to inject a dispatcher that sends actions to the store.

```swift
struct TodosView: ConnectableView {
  @MappedDispatch() private var dispatch

  func map(state: AppState) -> OrderedState<Todo>? {
    state.todos
  }

  func body(props: OrderedState<Todo>): some View {
    List {
      ForEach(todos) { todo in
        TodoItemRow(item: todo)
      }
      .onDelete { self.dispatch(TodoAction.removeTodos(at: $0)) }
      .onMove { self.dispatch(TodoAction.moveTodos(from: $0, to: $1)) }
    }
  }
}
```

The view can be placed like another:
```swift
struct RootView: View {

  var body: some View {
    TodosView()
  }
}
```

## Passing Data to a Connectable View
In some cases, a connected view needs external information to map the state to its props, such as an identifier. Simply add any needed variables to your view, and access them in the mapping function.

```swift
struct TodoDetailsView: ConnectableView {
  var id: String

  func map(state: TodoList) -> Todo? {
    state[id]
  }
}

// Somewhere else in the view hierarchy:

TodoDetailsView(id: "123")
```

## Binding<_> Support

SwiftUI has a focus on two-way bindings that connect to a single value source. To support updates through actions, SwiftDux provides a convenient API in the `ConnectableView` protocol using a `StateBinder` object. Use the `map(state:binder:)` method on the protocol as shown below. It provides a value to the text field, and dispatches an action when the text value changes.

```swift
struct LoginForm: View {

  struct Props: Equatable {
    @Binding var email: String
  }

  func map(state: AppState, binder: StateBinder) -> Props? {
    Props(
      email: binder.bind(state.loginForm.email) { 
        LoginFormAction.setEmail($0)
      }
    )
  }

  func body(props: Props) -> some View {
    VStack {
      TextField("Email", text: $props.email)
      /* ... */
    }
  }
}
```

## Previewing Connected Views
To preview a connected view by itself, you can provide a store that contains the parent state and reducer it maps from. This preview is based on a view in the Todo List Example project. Make sure to add `provideStore(_:)` after the connect method.

```swift
#if DEBUG
public enum TodoRowContainer_Previews: PreviewProvider {
  static var store: Store<TodoList> {
    Store(
      state: TodoList(
        id: "1",
        name: "TodoList",
        todos: .init([
          Todo(id: "1", text: "Get milk")
        ])
      ),
      reducer: TodosReducer()
    )
  }
  
  public static var previews: some View {
    TodoRowContainer(id: "1")
      .provideStore(store)
  }
  
}
#endif
```

## Action Plans
An `ActionPlan` is a special kind of action that can be used to group other actions together or perform any kind of async logic.

```swift
/// Dispatch multiple actions together:

let plan = ActionPlan<AppState> { store in
  store.send(actionA)
  store.send(actionB)
  store.send(actionC)
}

/// Perform async operations:

let plan = ActionPlan<AppState> { store in
  DispatchQueue.global().async {
    store.send(actionA)
    store.send(actionB)
    store.send(actionC)
  }
}

/// Publish actions to the store:

let plan = ActionPlan<AppState> { store, completed in
  let actions = [
    actionA,
    actionB,
    actionC
  ].publisher
  return actions.send(to: store, receivedCompletion: completed)
}

/// In a View, dispatch the plan like any other action:

dispatch(plan)
```

## Query External Services
Action plans can be used in conjunction with the `onAppear(dispatch:)` view modifier to connect to external data sources when a view appears. If the action plan returns a publisher, it will automatically cancel when the view disappears. Optionally, use `onAppear(dispatch:cancelOnDisappear:)` if the publisher should continue.

Action plans can also subscribe to the store. This is useful when the query needs to be refreshed if the application state changes. Rather than imperatively handling this by re-sending the action plan, it can be done more declaratively within it. The store's `didChange` subject will emit at least once after the action plan returns a publisher.

Here's an example of an action plan that queries for todos. It updates whenever the filter changes. It also debounces to reduce the amount of queries sent to the external services.

```swift
struct ActionPlans {
  var services: Services
}

extension ActionPlans {

  var queryTodos: Action {
    ActionPlan<AppState> { store, completed in
      store.didChange
        .map { _ in store.state.todoList.filterBy }
        .removeDuplicates()
        .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
        .flatMap { filter in self.services.queryTodos(filter: filter) }
        .catch { _ in Just<[TodoItem]>([]) }
        .map { todos -> Action in TodoListAction.setTodos(todos) }
        .send(to: store, receivedCompletion: completed)
    }
  }
}

struct TodoListView: ConnectableView {
  @Environment(\.actionPlans) private var actionPlans

  func map(state: AppState) -> [TodoItem]? {
    state.todoList.items
  }

  func body(props: [TodoItem]) -> some View {
    renderTodos(todos: props)
      .onAppear(dispatch: actionPlans.queryTodos)
  }

  // ...
}
```

[swift-image]: https://img.shields.io/badge/swift-5.1-orange.svg
[ios-image]: https://img.shields.io/badge/platforms-iOS%2013%20%7C%20macOS%2010.15%20%7C%20tvOS%2013%20%7C%20watchOS%206-222.svg
[swift-url]: https://swift.org/
[license-image]: https://img.shields.io/badge/License-MIT-blue.svg
[license-url]: LICENSE
[travis-image]: https://img.shields.io/travis/dbader/node-datadog-metrics/master.svg
[travis-url]: https://travis-ci.org/dbader/node-datadog-metrics
[codebeat-image]: https://codebeat.co/badges/c19b47ea-2f9d-45df-8458-b2d952fe9dad
[codebeat-url]: https://codebeat.co/projects/github-com-vsouza-awesomeios-com
[github-workflow-image]: https://github.com/StevenLambion/SwiftDux/workflows/build/badge.svg
[codecov-image]: https://codecov.io/gh/StevenLambion/SwiftDux/branch/master/graph/badge.svg
