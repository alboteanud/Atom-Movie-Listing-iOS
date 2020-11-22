//
//  Server.swift
//  Atom Movie Listing
//
//  Created by Dan Alboteanu on 17.11.2020.
//

import Foundation
import UIKit

protocol Server {
    // Fetch any entries on the server that are on the page number
    @discardableResult
    func fetchServerEntries(pageNumber: Int32, completion: @escaping (Result<ServerResult, Error>) -> Void)-> URLSessionDataTask?
    
    func fetchImage(_ posterPath: String?, completion: @escaping (UIImage? ) -> Void) -> URLSessionDataTask?
    
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
    let release_date: String?
    let popularity: Float?
    let original_language: String?
    let vote_average: Float?
}

struct ServerResult: Codable {
    let results: [ServerEntry]
    let page: Int32
}
// response
//{
//"page": 3,
//"total_results": 10000,
//"total_pages": 500,
//"results": [
//{"popularity": 1387.546,
//"vote_count": 338,
//"video": false,
//"poster_path": "/7D430eqZj8y3oVkLFfsWXGRcpEG.jpg",
//"id": 528085,
//"adult": false,
//"backdrop_path": "/5UkzNSOK561c2QRy2Zr4AkADzLT.jpg",
//"original_language": "en",
//"original_title": "2067",
//"genre_ids": [878,53,18],
//"title": "2067",
//"vote_average": 4.7,
//"overview": "A lowly utility worker is called to the future by a mysterious radio signal, he must leave his dying wife to embark on a journey that will force him to face his deepest fears in an attempt to change the fabric of reality and save humankind from its greatest environmental crisis yet.",
//"release_date": "2020-10-01"}

struct ServerEntryResult: Codable {
    struct genre : Codable {
        let id: Int?
        let name : String?
        
    }
    struct production_company : Codable {
        let name: String?
        let logo_path: String?
    }
    struct production_country : Codable {
        let name: String?
    }
    let genres: [genre]?
    let title: String?
    let production_companies: [production_company]?
    let production_countries: [production_country]?
    
}




//"adult": false,
//"backdrop_path": "/aO5ILS7qnqtFIprbJ40zla0jhpu.jpg",
//"belongs_to_collection": null,
//"budget": 0,
//"genres": [
//{
//"id": 28,
//"name": "Action"
//},
//{
//"id": 53,
//"name": "Thriller"
//},
//{
//"id": 12,
//"name": "Adventure"
//},
//{
//"id": 18,
//"name": "Drama"
//}
//],
//"homepage": "https://xmovies8.app/",
//"id": 741067,
//"imdb_id": "tt10804786",
//"original_language": "en",
//"original_title": "Welcome to Sudden Death",
//"overview": "Jesse Freeman is a former special forces officer and explosives expert now working a regular job as a security guard in a state-of-the-art basketball arena. Trouble erupts when a tech-savvy cadre of terrorists kidnap the team's owner and Jesse's daughter during opening night. Facing a ticking clock and impossible odds, it's up to Jesse to not only save them but also a full house of fans in this highly charged action thriller.",
//"popularity": 770.24,
//"poster_path": "/elZ6JCzSEvFOq4gNjNeZsnRFsvj.jpg",
//"production_companies": [],
//"production_countries": [
//{
//"iso_3166_1": "CA",
//"name": "Canada"
//},
//{
//"iso_3166_1": "FR",
//"name": "France"
//},
//{
//"iso_3166_1": "JP",
//"name": "Japan"
//},
//{
//"iso_3166_1": "GB",
//"name": "United Kingdom"
//},
//{
//"iso_3166_1": "US",
//"name": "United States of America"
//}
//],
//"release_date": "2020-09-29",
//"revenue": 0,
//"runtime": 80,
//"spoken_languages": [
//{
//"english_name": "English",
//"iso_639_1": "en",
//"name": "English"
//},
//{
//"english_name": "German",
//"iso_639_1": "de",
//"name": "Deutsch"
//}
//],
//"status": "Released",
//"tagline": "",
//"title": "Welcome to Sudden Death",
//"video": false,
//"vote_average": 6.4,
//"vote_count": 161



