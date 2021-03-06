//
//  ContentView.swift
//  16-SearchBar
//
//  Created by Le Xuan Quynh on 2020/02/12.
//  Copyright © 2020 Le Xuan Quynh. All rights reserved.
//

import SwiftUI



final class OtherSearchTextWrapper: SearchTextObservable {
    var searchPageListener = SearchPageListener()

    override func onUpdateTextDebounced(text: String) {
        searchPageListener.text = text
        searchPageListener.currentPage = 1
    }
}

struct ContentView: View {
    @State private var searchTextWrapper = OtherSearchTextWrapper()
    @State private var isSearching = false

    private var searchField: some View {
        SearchFieldView(searchTextWrapper: searchTextWrapper,
                        placeholder: "Search another...",
                        isSearching: $isSearching)
            .onPreferenceChange(OffsetTopPreferenceKey.self) { _ in
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }

    var body: some View {
        List {
            Section {
                searchField
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
