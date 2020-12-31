//
//  GithubAPI.swift
//  CombineDemo
//
//  Created by MC on 2020/12/29.
//

import Foundation
import Combine

enum GithubAPIError: Error, LocalizedError {
    case unknown
    case apiError(reason: String)
    case networkError(from: URLError)
    
    var errorDescription: String? {
        switch self {
        case .unknown:
            return "Unknown error"
        case .apiError(let reason):
            return reason
        case .networkError(let from):
            return from.localizedDescription
        }
    }
}

struct GithubAPI {
    /// 加载
    static let networkActivityPublisher = PassthroughSubject<Bool, Never>()
    
    /// 请求数据
    static func fetch(url: URL) -> AnyPublisher<Data, GithubAPIError> {
        return URLSession.shared.dataTaskPublisher(for: url)
            .handleEvents(receiveCompletion: { _ in
                networkActivityPublisher.send(false)
            }, receiveCancel: {
                networkActivityPublisher.send(false)
            }, receiveRequest: { _ in
                networkActivityPublisher.send(true)
            })
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw GithubAPIError.unknown
                }
                switch httpResponse.statusCode {
                case 401:
                    throw GithubAPIError.apiError(reason: "Unauthorized")
                case 403:
                    throw GithubAPIError.apiError(reason: "Resource forbidden")
                case 404:
                    throw GithubAPIError.apiError(reason: "Resource not found")
                case 405..<500:
                    throw GithubAPIError.apiError(reason: "client error")
                case 500..<600:
                    throw GithubAPIError.apiError(reason: "server error")
                default: break
                }
                
                return data
            }
            .mapError { error in
                if let err = error as? GithubAPIError {
                    return err
                }
                if let err = error as? URLError {
                    return GithubAPIError.networkError(from: err)
                }
                return GithubAPIError.unknown
            }
            .eraseToAnyPublisher()
    }
}
