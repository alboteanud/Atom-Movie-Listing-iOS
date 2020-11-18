//
//  Server.swift
//  Atom Movie Listing
//
//  Created by Dan Alboteanu on 17.11.2020.
//

import Foundation

protocol Server {
    func fetchMovies(since startDate: Date, completion: @escaping (Result<[ServerEntry], Error>) -> Void)-> URLSessionDataTask?
}

// A cancellable download task.
protocol DownloadTask {
    func cancel()
    var isCancelled: Bool { get }
}

// A struct representing the response from the cloud.
struct ServerEntry : Codable {
    let poster_path: String?
    let id: Int32
    let title: String?
//    let timestamp: Date
}

struct ServerResult: Codable {
    let results: [ServerEntry]
}




