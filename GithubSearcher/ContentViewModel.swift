//
//  ContentViewModel.swift
//  GithubSearcher
//
//  Created by Kenta Matsue on 2022/03/03.
//

import Foundation
import Combine

class ContentViewModel: ObservableObject {
    private var apiclient = APIClient()
    @Published var repositories: [GitHubRepository] = []
    private var cancellable: AnyCancellable?
    
    func fetch() {
        let request = GitHubSearchRepositoriesAPIRequest()
        apiclient.request(request) { result in
            switch(result) {
            case let .success(model):
                DispatchQueue.main.async {
                    self.repositories = model?.items ?? []
                }
            case let .failure(error):
                switch error {
                case let .server(status):
                    print("Error!! StatusCode: \(status)")
                case .noResponse:
                    print("Error!! No Response")
                case let .unknown(e):
                    print("Error!! Unknown: \(e)")
                default:
                    print("Error!! \(error)")
                }
            }
        }
    }
    
    func fetchWithCombine() {
        let request = GitHubSearchRepositoriesAPIRequest()
        cancellable = apiclient.requestWithPublisher(request, decoder: request.decoder)
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { completion in
            switch completion {
            case .failure(let error):
                if let apiError = error as? APIError {
                    print("error: \(apiError)")
                }
            case .finished:
                print("employee finished")
            }
        }, receiveValue: { model in
            self.repositories = model.items ?? []
        })
    }
    
    func fetchWithAsync() {
        Task {
            let request = GitHubSearchRepositoriesAPIRequest()
            do {
                let model = try await apiclient.requestWithAsync(request)
                self.repositories = model?.items ?? []
            } catch let decodeError {
                throw APIError.decode(decodeError)
            }
        }
    }
}
