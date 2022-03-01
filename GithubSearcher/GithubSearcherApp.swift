//
//  GithubSearcherApp.swift
//  GithubSearcher
//
//  Created by Kenta Matsue on 2022/03/01.
//

import SwiftUI

@main
struct GithubSearcherApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
