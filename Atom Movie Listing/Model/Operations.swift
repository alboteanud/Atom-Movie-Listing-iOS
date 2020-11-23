//
//  PersistentContainer.swift
//  Atom Movie Listing
//
//  Created by Dan Alboteanu on 17.11.2020.
//

import Foundation
import CoreData
import UIKit

struct Operations {
    // Returns an array of operations for fetching the latest entries and then adding them to the Core Data store.
    static func getOperationsToFetchLatestEntries(using context: NSManagedObjectContext, server: Server) -> [Operation] {
        let fetchMostRecentEntry = FetchMostRecentEntryOperation(context: context)
        let downloadFromServer = DownloadEntriesFromServerOperation(context: context, server: server)
        let passPageToServer = BlockOperation { [unowned fetchMostRecentEntry, unowned downloadFromServer] in
            downloadFromServer.pageNumber = getNextPageNumber(feedEntry: fetchMostRecentEntry.result)
        }
        passPageToServer.addDependency(fetchMostRecentEntry)
        downloadFromServer.addDependency(passPageToServer)
        
        let addToStore = AddEntriesToStoreOperation(context: context)
        let passServerResultsToStore = BlockOperation { [unowned downloadFromServer, unowned addToStore] in
            guard case let .success(serverResult)? = downloadFromServer.result else {
                addToStore.cancel()
                return
            }
            addToStore.serverResult = serverResult
        }
        passServerResultsToStore.addDependency(downloadFromServer)
        addToStore.addDependency(passServerResultsToStore)
        
        return [fetchMostRecentEntry,
                passPageToServer,
                downloadFromServer,
                passServerResultsToStore,
                addToStore]
    }

    static func getOperationsToFetchImage(using context: NSManagedObjectContext, server: Server) -> [Operation] {
        let fetchMostRecentEntry = FetchMostRecentEntryOperation(context: context)
        let downloadFromServer = DownloadEntriesFromServerOperation(context: context, server: server)
        let passPageToServer = BlockOperation { [unowned fetchMostRecentEntry, unowned downloadFromServer] in
            downloadFromServer.pageNumber = getNextPageNumber(feedEntry: fetchMostRecentEntry.result)
        }
        passPageToServer.addDependency(fetchMostRecentEntry)
        downloadFromServer.addDependency(passPageToServer)
        
        let addToStore = AddEntriesToStoreOperation(context: context)
        let passServerResultsToStore = BlockOperation { [unowned downloadFromServer, unowned addToStore] in
            guard case let .success(serverResult)? = downloadFromServer.result else {
                addToStore.cancel()
                return
            }
            addToStore.serverResult = serverResult
        }
        passServerResultsToStore.addDependency(downloadFromServer)
        addToStore.addDependency(passServerResultsToStore)
        
        return [fetchMostRecentEntry,
                passPageToServer,
                downloadFromServer,
                passServerResultsToStore,
                addToStore]
    }
}


func getNextPageNumber(feedEntry: FeedEntry?) -> Int32 {
    let currentPage = feedEntry?.page ?? 0
    let nextPage = currentPage + 1
    return nextPage
}

// Fetches the most recent entry from the Core Data store.
class FetchMostRecentEntryOperation: Operation {
    private let context: NSManagedObjectContext
    
    var result: FeedEntry?
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    override func main() {
        let request: NSFetchRequest<FeedEntry> = FeedEntry.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: #keyPath(FeedEntry.page), ascending: false)]
        request.fetchLimit = 1
        
        context.performAndWait {
            do {
                let fetchResult = try context.fetch(request)
                guard !fetchResult.isEmpty else { return }
                
                result = fetchResult[0]
            } catch {
                print("Error fetching from context: \(error)")
            }
        }
    }
}

// Downloads entries created after the specified date.
class DownloadEntriesFromServerOperation: Operation {
    enum OperationError: Error {
        case cancelled
    }

    private let context: NSManagedObjectContext
    private let server: Server
    var pageNumber: Int32?
    
    var result: Result<ServerResult, Error>?
    
    private var downloading = false
    private var currentDownloadTask: URLSessionDataTask?
    
    init(context: NSManagedObjectContext, server: Server) {
        self.context = context
        self.server = server
    }
    
    convenience init(context: NSManagedObjectContext, server: Server, pageNumber: Int32) {
        self.init(context: context, server: server)
        self.pageNumber = pageNumber
    }
    
    override var isAsynchronous: Bool {
        return true
    }
    
    override var isExecuting: Bool {
        return downloading
    }
    
    override var isFinished: Bool {
        return result != nil
    }
    
    override func cancel() {
        super.cancel()
        if let currentDownloadTask = currentDownloadTask {
            currentDownloadTask.cancel()
        }
    }
    
    func finish(result: Result<ServerResult, Error>) {
        guard downloading else { return }
        
        willChangeValue(forKey: #keyPath(isExecuting))
        willChangeValue(forKey: #keyPath(isFinished))
        
        downloading = false
        self.result = result
        currentDownloadTask = nil
        
        didChangeValue(forKey: #keyPath(isFinished))
        didChangeValue(forKey: #keyPath(isExecuting))
    }

    override func start() {
        willChangeValue(forKey: #keyPath(isExecuting))
        downloading = true
        didChangeValue(forKey: #keyPath(isExecuting))
        guard !isCancelled, let pageNumber = pageNumber else {
            finish(result: .failure(OperationError.cancelled))
            return
        }
        currentDownloadTask = server.fetchServerEntries(pageNumber: pageNumber, completion: finish)
        currentDownloadTask?.resume()
    }
}

// An extension to create a FeedEntry object from the server representation of an entry.
extension FeedEntry {
    convenience init(context: NSManagedObjectContext, serverEntry: ServerEntry, page: Int32) {
        self.init(context: context)
        self.id = serverEntry.id
        self.title = serverEntry.title
        self.poster_path = serverEntry.poster_path
        self.overview = serverEntry.overview
        self.release_date = getDate(serverEntry.release_date)
        self.popularity = serverEntry.popularity ?? 0
        self.original_language = original_language
        self.vote_average = vote_average
        self.page = page
    }
}

func getDate(_ dateString: String?) -> Date {
    guard let dateString = dateString else {
        return Date()
    }
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss" // "2020-10-01"
    let date = dateFormatter.date(from: dateString) ?? Date()
//    print(date.debugDescription)
    return date
}

// Add entries returned from the server to the Core Data store.
class AddEntriesToStoreOperation: Operation {
    private let context: NSManagedObjectContext
    var serverResult: ServerResult?
    var delay: TimeInterval = 0

    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    convenience init(context: NSManagedObjectContext, serverResult: ServerResult, delay: TimeInterval? = nil) {
        self.init(context: context)
        self.serverResult = serverResult
        if let delay = delay {
            self.delay = delay
        }
    }
    
    override func main() {
        guard let entries = serverResult?.results,
              let page = serverResult?.page else { return }

        context.performAndWait {
            do {
                for entry in entries {
                    _ = FeedEntry(context: context, serverEntry: entry, page: page)
                    
                    print("Adding entry with title: \(String(describing: entry.title))")
                    
                    // Simulate a slow process by sleeping
                    if delay > 0 {
                        Thread.sleep(forTimeInterval: delay)
                    }
                    try context.save()

                    if isCancelled {
                        break
                    }
                }
            } catch {
                print("Error adding entries to store: \(error)")
            }
        }
    }
}

// Delete feed entries that match the predicate parameter from the Core Data store.
class DeleteFeedEntriesOperation: Operation {
    private let context: NSManagedObjectContext
    var predicate: NSPredicate?
    var delay: TimeInterval = 1
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    convenience init(context: NSManagedObjectContext, predicate: NSPredicate?, delay: TimeInterval? = nil) {
        self.init(context: context)
        self.predicate = predicate
        if let delay = delay {
            self.delay = delay
        }
    }
    
    override func main() {
        let fetchRequest: NSFetchRequest<FeedEntry> = FeedEntry.fetchRequest()
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(FeedEntry.release_date), ascending: true)]
        
        context.performAndWait {
            do {
                let entriesToDelete = try context.fetch(fetchRequest)
                for entry in entriesToDelete {
                    print("Deleting entry with date: \(entry.release_date?.description ?? "(nil)")")
                    
                    context.delete(entry)
                    
                    // Simulate a slow process by sleeping.
                    if delay > 0 {
                        Thread.sleep(forTimeInterval: delay)
                    }

                    if isCancelled {
                        break
                    }
                }
                try context.save()
            } catch {
                print("Error deleting entries: \(error)")
            }
        }
    }
}
