//
//  DemoList.swift
//  ListCRUDSwiftUI
//
//  Created by Vadym Bulavin on 2/5/20.
//  Copyright © 2020 Vadym Bulavin. All rights reserved.
//

import SwiftUI
import MobileCoreServices

struct Item: Identifiable {
    let id = UUID()
    let title: String
}

struct DemoList: View {
    @State private var items: [Item] = []
    @State private var editMode = EditMode.inactive
    private static var count = 0

    var body: some View {
        NavigationView {
            List {
                ForEach(items) { item in
                    Text(item.title)
                }
                .onDelete(perform: onDelete)
                .onMove(perform: onMove)
                .onInsert(of: [String(kUTTypeURL)], perform: onInsert)
            }
            .navigationBarTitle("List")
            .navigationBarItems(leading: EditButton(), trailing: addButton)
            .environment(\.editMode, $editMode)
        }
    }
    
    private var addButton: some View {
        switch editMode {
        case .inactive:
            return AnyView(Button(action: onAdd) { Image(systemName: "plus") })
        default:
            return AnyView(EmptyView())
        }
    }
    
    private func onDelete(offsets: IndexSet) {
        items.remove(atOffsets: offsets)
    }
    
    private func onMove(source: IndexSet, destination: Int) {
        items.move(fromOffsets: source, toOffset: destination)
    }
    
    private func onInsert(at offset: Int, itemProvider: [NSItemProvider]) {
        for provider in itemProvider {
            if provider.canLoadObject(ofClass: URL.self) {
                _ = provider.loadObject(ofClass: URL.self) { url, error in
                    DispatchQueue.main.async {
                        url.map { self.items.insert(Item(title: $0.absoluteString), at: offset) }
                    }
                }
            }
        }
    }
    
    private func onAdd() {
        items.append(Item(title: "Item #\(Self.count)"))
        Self.count += 1
    }
}
