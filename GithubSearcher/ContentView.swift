//
//  ContentView.swift
//  GithubSearcher
//
//  Created by Kenta Matsue on 2022/03/01.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @StateObject var viewModel: ContentViewModel

    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.repositories) { item in
                    Text(item.name)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: deleteItems) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
                ToolbarItem {
                    Button(action: addItem) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: editItems) {
                        Label("Add Item", systemImage: "trash")
                    }
                }
            }
            Text("Select an item")
        }
    }

    private func addItem() {
        viewModel.fetch()
    }

    private func deleteItems() {
        viewModel.fetchWithCombine()
    }
    
    private func editItems() {
        viewModel.fetchWithAsync()
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(viewModel: ContentViewModel())
    }
}
