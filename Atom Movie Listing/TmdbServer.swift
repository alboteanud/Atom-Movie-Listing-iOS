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

    
    func fetchMovies(since startDate: Date, completion: @escaping (Result<[ServerEntry], Error>) -> Void)  {
        let urlString = getEndpointUrl(pageNumber: 1)
        guard let url = URL(string: urlString)else {
            completion(.failure(DownloadError.invalidRequest))
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
        guard let data = data else {
            completion(.failure(DownloadError.emptyResponse))
            return
        }
//            let string = String(data: data, encoding: .utf8)
//            print(string)
            do {
//                let decoded2 = try JSONDecoder().decode(ServerResult2.self, from: data)
                let decoded = try JSONDecoder().decode(ServerResult.self, from: data)
                if decoded.results.count > 0 {
                    self.queue.async {
                        completion(.success(decoded.results))
                    }
                } else {
                    return completion(.failure(DownloadError.emptyResponse))}
            } catch {
                completion(.failure(DownloadError.networkError))}
            }
        task.resume()
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
    
//    struct ServerEntry : Codable {
//        let poster_path: String?
//        let id: Int16
//        let title: String?
//    //    let timestamp: Date
//    }
//
//    struct ServerResult: Codable {
//        let results: [ServerEntry]
//    }
    
    struct ServerEntry2 : Codable {
        let id : Int32?
        let title: String?
        let poster_path: String?
    }

    struct ServerResult2: Codable {
        let page: Int?
        let total_results: Int?
        let results: [ServerEntry2]
        
    }
    
//    {
//    "page": 1,
//    "total_results": 10000,
//    "total_pages": 500,
//    "results": [
//    {
//    "popularity": 2139.868,
//    "vote_count": 189,
//    "video": false,
//    "poster_path": "/rUAztxhGWKPeXZFrqjzaFk1uQir.jpg",
//    "id": 671039,

//    func fetchEntries(since startDate: Date, completion: @escaping (Result<[ServerEntry], Error>) -> Void) -> DownloadTask {
//        let now = Date()
//
//        let entries = generateFakeEntries(from: startDate, to: now)
//
//        return TmdbDownloadTask(delay: Double.random(in: 0..<2.5), queue: queue, onSuccess: {
//            completion(.success(entries))
//        }, onCancelled: {
//            completion(.failure(DownloadError.cancelled))
//        })
//
//   }
    
    func getEndpointUrl(pageNumber: Int) -> String {
//        return "https://picsum.photos/v2/list?page=\(String(pageNumber))&limit=10"
        return "https://api.themoviedb.org/3/movie/popular?api_key=8700e0b55b9438b27963771c2aff54f5"
    }
    
}
