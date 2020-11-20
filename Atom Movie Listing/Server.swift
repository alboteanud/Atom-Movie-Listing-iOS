//
//  Server.swift
//  Atom Movie Listing
//
//  Created by Dan Alboteanu on 17.11.2020.
//

import Foundation

protocol Server {
    // Fetch any entries on the server that are more recent than the start date.
    @discardableResult
    func fetchEntries(since startDate: Date, completion: @escaping (Result<[ServerEntry], Error>) -> Void)-> URLSessionDataTask?
}

// A cancellable download task.
protocol DownloadTask {
    func cancel()
    var isCancelled: Bool { get }
}

// A struct representing the response from the server.
struct ServerEntry : Codable {
    let poster_path: String?
    let id: Int32
    let title: String?
    let overview: String?
//    let timestamp: Date
}

struct ServerResult: Codable {
    let results: [ServerEntry]
}

// A struct representing the response from the server for a single feed entry.
//struct ServerEntry: Codable {
//    struct Color: Codable {
//        var red: Double
//        var blue: Double
//        var green: Double
//    }
//
//    let timestamp: Date
//    let firstColor: Color
//    let secondColor: Color
//    let gradientDirection: Double
//}




