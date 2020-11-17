//
//  ViewController.swift
//  Atom Movie Listing
//
//  Created by Dan Alboteanu on 17.11.2020.
//

import UIKit
import BackgroundTasks

class ViewController: UIViewController {
    
    private let server: Server = TmdbServer()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        // MARK: Registering Launch Handlers for Tasks
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.albotenu.AtomMovieListing.refresh", using: nil) { task in
            // Downcast the parameter to an app refresh task as this identifier is used for a refresh request.
            self.handleAppRefresh(task: task as! BGAppRefreshTask)
        }
    }

    @IBAction func buttonTapped(_ sender: Any) {
//        scheduleAppRefresh()
        forceExec()
    }
    
    func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "com.albotenu.AtomMovieListing.refresh")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // Fetch no earlier than 15 minutes from now
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule app refresh: \(error)")
        }
    }
    
    // Fetch the latest feed entries from server.
    func handleAppRefresh(task: BGAppRefreshTask) {
//        scheduleAppRefresh()
        
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        
        let context = PersistentContainer.shared.newBackgroundContext()
        let operations = Operations.getOperationsToFetchLatestEntries(using: context, server: server)
        let lastOperation = operations.last!
        
        task.expirationHandler = {
            // After all operations are cancelled, the completion block below is called to set the task to complete.
            queue.cancelAllOperations()
        }

        lastOperation.completionBlock = {
            task.setTaskCompleted(success: !lastOperation.isCancelled)
        }

        queue.addOperations(operations, waitUntilFinished: false)
    }
    
    func forceExec() {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        
        let context = PersistentContainer.shared.newBackgroundContext()
        let operations = Operations.getOperationsToFetchLatestEntries(using: context, server: server)
        let lastOperation = operations.last!
        
//        task.expirationHandler = {
//            // After all operations are cancelled, the completion block below is called to set the task to complete.
//            queue.cancelAllOperations()
//        }

//        lastOperation.completionBlock = {
//            task.setTaskCompleted(success: !lastOperation.isCancelled)
//        }

        queue.addOperations(operations, waitUntilFinished: false)
    }

}

