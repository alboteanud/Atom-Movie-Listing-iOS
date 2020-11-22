//
//  Mocks.swift
//  Atom Movie Listing
//
//  Created by Dan Alboteanu on 20.11.2020.
//

import Foundation
import CoreData

// Simulates a remote server by generating randomized ServerEntry results
class MockServer: Server {
    
    private let queue = DispatchQueue(label: "TmdbServerQueue")

    enum DownloadError: Error {
        case cancelled
        case invalidRequest
        case emptyResponse
        case networkError
    }

    private class MockDownloadTask: DownloadTask {
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
    func fetchEntries (since startDate: Date, completion: @escaping (Result<[ServerEntry], Error>) -> Void) -> URLSessionDataTask? {
        let urlString = getEntriesEndpointUrl(pageNumber: 1)
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
                        completion(.success(decoded.results))
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
    func fetchEntry (entryId: Int32, completion: @escaping (ServerResultSingleEntry?) -> Void) -> URLSessionDataTask? {
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
                let decoded = try JSONDecoder().decode(ServerResultSingleEntry.self, from: data)
//                print("downloaded entry data genres: \(String(describing: decoded.genres))")
                self.queue.async {
                    completion(decoded)
                }
            } catch {
                print("error while parsing json response. \(error.localizedDescription)")
                completion(nil)}
        }
    }
    
    func getEntriesEndpointUrl(pageNumber: Int) -> String {
        return "https://api.themoviedb.org/3/movie/popular?api_key=8700e0b55b9438b27963771c2aff54f5"
    }
    
    func getEntryEndpointUrl(entryId: Int32) -> String {
        // https://api.themoviedb.org/3/movie/741067?api_key=8700e0b55b9438b27963771c2aff54f5
        let url = "https://api.themoviedb.org/3/movie/\(entryId)?api_key=8700e0b55b9438b27963771c2aff54f5"
        return url
    }
    
    func buildPhotoDownloadUrl(photoPath: String) -> URL? {
        // https://image.tmdb.org/t/p/w500/kqjL17yufvn9OVLyXYpvtyrFfak.jpg
        let urlString = "https://image.tmdb.org/t/p/w500\(photoPath)"
//        print(urlString)
        guard let url = URL(string: urlString) else { return nil}
        //        print ("paths", url.pathComponents)
        return url
        
//        if url.pathComponents.count > 2 {
//            let photoId = url.pathComponents[2]
//            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
//            components.path = "/id/\(photoId)/50/50.jpg"
//            //            print(components.url!)
//            // expected result: "https://i.picsum.photos/id/1006/50/50.jpg"
//            return components.url!
//        }
//        return nil
    }
    
    
    
}

extension PersistentContainer {
    // Fills the Core Data store with initial fake data
    // If onlyIfNeeded is true, only does so if the store is empty
    func loadInitialData(onlyIfNeeded: Bool = true, server: Server) {
        let context = newBackgroundContext()
        context.perform {
            do {
                let allEntriesRequest: NSFetchRequest<NSFetchRequestResult> = FeedEntry.fetchRequest()
                if !onlyIfNeeded {
                    // Delete all data currently in the store
                    let deleteAllRequest = NSBatchDeleteRequest(fetchRequest: allEntriesRequest)
                    deleteAllRequest.resultType = .resultTypeObjectIDs
                    let result = try context.execute(deleteAllRequest) as? NSBatchDeleteResult
                    NSManagedObjectContext.mergeChanges(fromRemoteContextSave: [NSDeletedObjectsKey: result?.result as Any],
                                                        into: [self.viewContext])
                }
                if try !onlyIfNeeded || context.count(for: allEntriesRequest) == 0 {
                    let now = Date()
                    let start = now - (7 * 24 * 60 * 60)
                    let end = now - (60 * 60)
                    
//                    _ = generateFakeEntries(from: start, to: end).map { FeedEntry(context: context, serverEntry: $0) }
                    self.fetchLatestEntries(server: server)
                    try context.save()
                    
                    self.lastCleaned = nil
                }
            } catch {
                print("Could not load initial data due to \(error)")
            }
        }
    }
    
    func fetchLatestEntries(server: Server){

        // update local DB
        let queue = OperationQueue()
        queue.qualityOfService = .userInitiated
        queue.maxConcurrentOperationCount = 1

        let context = newBackgroundContext()
        let operations = Operations.getOperationsToFetchLatestEntries(using: context, server: server)
        operations.last?.completionBlock = {
//            DispatchQueue.main.async {
       
//            }
        }
        queue.addOperations(operations, waitUntilFinished: false)
    }
    
}
