//
//  TmdbServer.swift
//  Atom Movie Listing
//
//  Created by Dan Alboteanu on 17.11.2020.
//

import Foundation
import CoreData

class TmdbServer: Server {
    private let queue = DispatchQueue(label: "TmdbServerQueue")

    enum DownloadError: Error {
        case cancelled
        case invalidRequest
        case emptyResponse
        case networkError
    }

    func fetchMovies(since startDate: Date, completion: @escaping (Result<[ServerEntry], Error>) -> Void) -> URLSessionDataTask? {
        let urlString = getEndpointUrl(pageNumber: 1)
        let url = URL(string: urlString)!   //        else {completion(.failure(DownloadError.invalidRequest))

        return URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else {
                completion(.failure(DownloadError.emptyResponse))
                        return
                    }
            do {
                let decoded = try JSONDecoder().decode(ServerResult.self, from: data)
                if decoded.results.count > 0 {
                    self.queue.async {
                        completion(.success(decoded.results))
                    }
                } else {
                    completion(.failure(DownloadError.emptyResponse))}
            } catch {
                completion(.failure(DownloadError.networkError))}
            }
    }
    
    struct Source : Codable {
        struct Features : Codable {
            struct Attributes : Codable {
                let cases7_per_100k: Double
            }
            let attributes: Attributes
        }
        let features: [Features]
    }
    
    func getEndpointUrl(pageNumber: Int) -> String {
        return "https://api.themoviedb.org/3/movie/popular?api_key=8700e0b55b9438b27963771c2aff54f5"
    }
    
}
