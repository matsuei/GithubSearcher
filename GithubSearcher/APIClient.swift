//
//  APIClient.swift
//  GithubSearcher
//
//  Created by Kenta Matsue on 2022/03/01.
//

import Foundation
import Combine

struct APIClient {
    func request<T: Requestable>(_ requestable: T, completion: @escaping(Result<T.Model?, APIError>) -> Void) {
        guard let request = requestable.urlRequest else { return }
        let task = URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
            if let error = error {
                completion(.failure(APIError.unknown(error)))
                return
            }
            guard let data = data, let response = response as? HTTPURLResponse else {
                completion(.failure(APIError.noResponse))
                return
            }

            if case 200..<300 = response.statusCode {
                do {
                    let model = try requestable.decode(from: data)
                    completion(.success(model))
                } catch let decodeError {
                    completion(.failure(APIError.decode(decodeError)))
                }
            } else {
                completion(.failure(APIError.server(response.statusCode)))
            }
        })
        task.resume()
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    func requestWithPublisher<T: Requestable>(_ requestable: T, decoder: JSONDecoder) -> AnyPublisher<T.Model, Error> {
        let result = URLSession.shared.dataTaskPublisher(for: requestable.urlRequest!)
            .tryMap({ data, response -> Data in
                guard let httpRes = response as? HTTPURLResponse else {
                    throw APIError.noResponse
                }
                if (200..<300).contains(httpRes.statusCode) == false {
                    throw APIError.server(httpRes.statusCode)
                }
                return data
            })
            .decode(type: T.Model.self, decoder: decoder) // 本当はTからdecoderを取得したい
            .eraseToAnyPublisher()
        return result
    }
    
    func requestWithAsync<T: Requestable>(_ requestable: T) async throws -> T.Model? {
        guard let request = requestable.urlRequest else {
            throw APIError.noResponse
        }
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpRes = response as? HTTPURLResponse else {
            throw APIError.noResponse
        }
        if case 200..<300 = httpRes.statusCode {
            do {
                let model = try requestable.decode(from: data)
                return model
            } catch let decodeError {
                throw APIError.decode(decodeError)
            }
        } else {
            throw APIError.server(httpRes.statusCode)
        }
    }
}

struct GitHubRepositories: Codable {
    let totalCount: Int
    let incompleteResults: Bool
    let items: [GitHubRepository]?
}

struct GitHubRepository: Codable, Identifiable {
    var id = UUID()
    let name: String
    let htmlURL: String
    
    private enum CodingKeys: String, CodingKey {
        case name
        case htmlURL = "htmlUrl"
    }
}

struct GitHubSearchRepositoriesAPIRequest: Requestable {
    var url: String {
        return "https://api.github.com/search/repositories?q=swift+api"
    }

    var httpMethod: String {
      return "GET"
    }

    var headers: [String : String] {
      return [:]
    }
    
    var body: Data? {
        return nil
    }
    
    var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }
    
    typealias Model = GitHubRepositories

    func decode(from data: Data) throws -> GitHubRepositories {
        return try decoder.decode(GitHubRepositories.self, from: data)
    }
}

protocol Requestable {
    associatedtype Model: Codable
    var url: String { get }
    var httpMethod: String { get }
    var headers: [String: String] { get }
    var body: Data? { get }
    var decoder: JSONDecoder { get }
    func decode(from data: Data) throws -> Model
}

extension Requestable {
    var urlRequest: URLRequest? {
        guard let url = URL(string: url) else { return nil }
        var request = URLRequest(url: url)
        if let body = body {
            request.httpBody = body
        }
        request.httpMethod = httpMethod
        headers.forEach { key, value in
            request.addValue(value, forHTTPHeaderField: key)
        }
        return request
    }
}

enum APIError: Error {
    case server(Int)
    case decode(Error)
    case noResponse
    case unknown(Error)
}
