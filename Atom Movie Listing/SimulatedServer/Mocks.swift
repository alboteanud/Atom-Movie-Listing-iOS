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

//    func fetchEntries(since startDate: Date, completion: @escaping (Result<[ServerEntry], Error>) -> Void) -> DownloadTask {
//        let now = Date()
//
//        let entries = generateFakeEntries(from: startDate, to: now)
//
//        return MockDownloadTask(delay: Double.random(in: 0..<2.5), queue: queue, onSuccess: {
//            completion(.success(entries))
//        }, onCancelled: {
//            completion(.failure(DownloadError.cancelled))
//        })
//    }

    // fetch movies
    func fetchEntries (since startDate: Date, completion: @escaping (Result<[ServerEntry], Error>) -> Void) -> URLSessionDataTask? {
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
    
    func getEndpointUrl(pageNumber: Int) -> String {
        return "https://api.themoviedb.org/3/movie/popular?api_key=8700e0b55b9438b27963771c2aff54f5"
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
    func loadInitialData(onlyIfNeeded: Bool = true) {
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
                    try context.save()
                    
                    self.lastCleaned = nil
                }
            } catch {
                print("Could not load initial data due to \(error)")
            }
        }
    }
}

//extension ServerEntry.Color {
//    static func makeRandom() -> ServerEntry.Color {
//        let randomRed = Double.random(in: 0...1)
//        let randomBlue = Double.random(in: 0...1)
//        let randomGreen = Double.random(in: 0...1)
//
//        return ServerEntry.Color(red: randomRed, blue: randomBlue, green: randomGreen)
//    }
//}
//
//extension ServerEntry {
//    static func makeRandom(timestamp: Date) -> ServerEntry {
//        return ServerEntry(timestamp: timestamp,
//                           firstColor: Color.makeRandom(),
//                           secondColor: Color.makeRandom(),
//                           gradientDirection: Double.random(in: 0..<360))
//    }
//}
//
//private func generateFakeEntries(from startDate: Date,
//                                 to endDate: Date,
//                                 interval: TimeInterval = 60 * 10,
//                                 variation: TimeInterval = 5 * 60) -> [ServerEntry] {
//    var entries = [ServerEntry]()
//    for time in stride(from: startDate.timeIntervalSince1970, to: endDate.timeIntervalSince1970, by: interval) {
//        let randomVariation = Double.random(in: -(variation)...(variation))
//        let fakeTime = max(startDate.timeIntervalSince1970, min(time + randomVariation, endDate.timeIntervalSince1970))
//        entries.append(ServerEntry.makeRandom(timestamp: Date(timeIntervalSince1970: fakeTime)))
//    }
//    return entries
//}
