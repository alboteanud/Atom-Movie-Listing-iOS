//
//  Mocks.swift
//  Atom Movie Listing
//
//  Created by Dan Alboteanu on 20.11.2020.
//

import Foundation
import CoreData
import UIKit

class MovieServer: Server {
    
    private let queue = DispatchQueue(label: "TmdbServerQueue")
    private let imageCache = NSCache<NSString, UIImage>()
    let myTmdbApiKey = "8700e0b55b9438b27963771c2aff54f5"

    enum DownloadError: Error {
        case cancelled
        case invalidRequest
        case emptyResponse
        case networkError
    }

    private class MyDownloadTask: DownloadTask {
        var isCancelled = false
        let onCancelled: () -> Void
        let queue: DispatchQueue

        init(delay: TimeInterval, queue: DispatchQueue, onSuccess: @escaping () -> Void, onCancelled: @escaping () -> Void) {
            self.onCancelled = onCancelled
            self.queue = queue

            queue.asyncAfter(deadline: .now() + delay) {
                if !self.isCancelled {
                    onSuccess()
                }
            }
        }

        func cancel() {
            queue.async {
                guard !self.isCancelled else { return }

                self.isCancelled = true
                self.onCancelled()
            }
        }
    }

    // fetch movies
    func fetchServerEntries (pageNumber: Int32, completion: @escaping (Result<ServerResult, Error>) -> Void) -> URLSessionDataTask? {
        let urlString = getEntriesEndpointUrl(pageNumber: pageNumber)
        print(urlString)
        let url = URL(string: urlString)!   //        else {completion(.failure(DownloadError.invalidRequest))
        
        return URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else {
                print("downloaded data is nil.  \(String(describing: error?.localizedDescription))")
                completion(.failure(DownloadError.emptyResponse))
                return
            }
            do {
                let decoded = try JSONDecoder().decode(ServerResult.self, from: data)
                if decoded.results.count > 0 {
                    self.queue.async {
                        completion(.success(decoded))
                    }
                } else {
                    print("downloaded data is empty")
                    completion(.failure(DownloadError.emptyResponse))}
            } catch {
                print("error while parsing json response. \(error.localizedDescription)")
                completion(.failure(DownloadError.emptyResponse))}
        }
    }
    
    // fetch single movie
    func fetchServerEntry (entryId: Int32, completion: @escaping (ServerEntryResult?) -> Void) -> URLSessionDataTask? {
        let urlString = getEntryEndpointUrl(entryId: entryId)
        guard let url = URL(string: urlString)
        else {
            print("url malformed")
            return nil
            
        }
        
        return URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else {
                print("downloaded data is nil.  \(String(describing: error?.localizedDescription))")
                completion(nil)
                return
            }
            do {
                let decoded = try JSONDecoder().decode(ServerEntryResult.self, from: data)
//                print("downloaded entry data genres: \(String(describing: decoded.genres))")
                self.queue.async {
                    completion(decoded)
                }
            } catch {
                print("error while parsing json response. \(error.localizedDescription)")
                completion(nil)}
        }
    }
    
    func fetchImage(_ posterPath: String?, completion: @escaping (UIImage? ) -> Void) -> URLSessionDataTask? {
        guard let posterPath = posterPath else {
            completion(nil)
            return nil }
        if let imageFromCache = self.imageCache.object(forKey: posterPath as NSString) {
        self.queue.async {
//                let imageFromCacheWithFilter = imageFromCache.addFilter(filter: FilterType.Noir)
                completion(imageFromCache)
            }
            return nil
        }
        
        // TODO: get image from Core Data
        // ...

        
        // Let's go to the network
        let urlString = buildPhotoDownloadUrl(photoPath: posterPath)
        guard let url = URL(string: urlString) else {
            completion(nil)
            return nil}
        return URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
            guard
                let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
                let data = data, error == nil,
                let imageFromNetwork = UIImage(data: data)
            else {
                completion(nil)
                return }
            
            self.queue.async {
                completion(imageFromNetwork)
                self.imageCache.setObject(imageFromNetwork, forKey: posterPath as NSString)
            }
            
        })
    }
  
    func getEntriesEndpointUrl(pageNumber: Int32) -> String {
        return "https://api.themoviedb.org/3/movie/popular?api_key=\(myTmdbApiKey)&&page=\(pageNumber)"
    }
    
    // https://api.themoviedb.org/3/movie/741067?api_key=8700e0b55b9438b27963771c2aff54f5
    func getEntryEndpointUrl(entryId: Int32) -> String {
        let url = "https://api.themoviedb.org/3/movie/\(entryId)?api_key=\(myTmdbApiKey)"
        return url
    }
    
    // https://image.tmdb.org/t/p/w500/kqjL17yufvn9OVLyXYpvtyrFfak.jpg
    func buildPhotoDownloadUrl(photoPath: String) -> String {
        let urlString = "https://image.tmdb.org/t/p/w500\(photoPath)"
//        print(urlString)
        return urlString
    }
}

extension PersistentContainer {
    // Fills the Core Data store with initial server data
    // If onlyIfNeeded is true, only does so if the store is empty
    func loadInitialData(onlyIfNeeded: Bool = true, server: Server) {
        let context = newBackgroundContext()
        context.perform {
            do {
                let allEntriesRequest: NSFetchRequest<NSFetchRequestResult> = ListEntry.fetchRequest()
                if !onlyIfNeeded {
                    // Delete all data currently in the store
                    let deleteAllRequest = NSBatchDeleteRequest(fetchRequest: allEntriesRequest)
                    deleteAllRequest.resultType = .resultTypeObjectIDs
                    let result = try context.execute(deleteAllRequest) as? NSBatchDeleteResult
                    NSManagedObjectContext.mergeChanges(fromRemoteContextSave: [NSDeletedObjectsKey: result?.result as Any],
                                                        into: [self.viewContext])
                }
                if try !onlyIfNeeded || context.count(for: allEntriesRequest) == 0 {
                    self.downloadNewEntries(server: server, context:context)
                    server.fetchServerEntries(pageNumber: 1){_ in
                        
                    }
                    try context.save()
                    
                    self.lastCleaned = nil
                }
            } catch {
                print("Could not load initial data due to \(error)")
            }
        }
    }
    
    func downloadNewEntries(server: Server, context: NSManagedObjectContext){
        let queue = OperationQueue()
        queue.qualityOfService = .userInitiated
        queue.maxConcurrentOperationCount = 1
        let operations = Operations.getOperationsToFetchLatestEntries(using: context, server: server)
        operations.last?.completionBlock = {
//            DispatchQueue.main.async {  }
        }
        queue.addOperations(operations, waitUntilFinished: false)
    }
 
    
}
