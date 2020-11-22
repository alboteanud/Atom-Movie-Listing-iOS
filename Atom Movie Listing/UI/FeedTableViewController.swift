//
//  ViewController.swift
//  Atom Movie Listing
//
//  Created by Dan Alboteanu on 17.11.2020.
//

import UIKit
import CoreData

class FeedTableViewController: UITableViewController, NSFetchedResultsControllerDelegate {
    private let server: Server = MockServer()
    var fetchRequest: NSFetchRequest<FeedEntry>!
    
    private var fetchedResultsController: NSFetchedResultsController<FeedEntry>!
    
    @IBAction func updateButtonTapped(_ sender: Any) {
        fetchLatestEntries()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.titleView = getTitleView(titleText: "ATOM", imageName: "Atom")
        initFetchedResultsController()
    }
    
    func initFetchedResultsController(){
        if fetchRequest == nil {
            fetchRequest = FeedEntry.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(FeedEntry.popularity), ascending: false)]
        }
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                              managedObjectContext: PersistentContainer.shared.viewContext,
                                                              sectionNameKeyPath: nil,
                                                              cacheName: String(describing: self))
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch {
            print("Error fetching results: \(error)")
        }
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if fetchedResultsController.sections?.count ?? 0 > 0 {
            let sectionInfo = fetchedResultsController.sections![section]
            return sectionInfo.numberOfObjects
        } else { return 0 }
    }

    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange sectionInfo: NSFetchedResultsSectionInfo,
                    atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            tableView.insertSections(IndexSet(integer: sectionIndex), with: .automatic)
        case .delete:
            tableView.deleteSections(IndexSet(integer: sectionIndex), with: .automatic)
        default:
            return
        }
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange anObject: Any, at indexPath: IndexPath?,
                    for type: NSFetchedResultsChangeType,
                    newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            guard let newIndexPath = newIndexPath else { return }
            tableView.insertRows(at: [newIndexPath], with: .automatic)
        case .delete:
            guard let indexPath = indexPath else { return }
            tableView.deleteRows(at: [indexPath], with: .automatic)
        case .update:
            if let cell = tableView.cellForRow(at: indexPath!) as? FeedEntryTableViewCell {
                configure(cell: cell, at: indexPath!)
            }
        case .move:
            guard let indexPath = indexPath, let newIndexPath = newIndexPath else { return }
            tableView.moveRow(at: indexPath, to: newIndexPath)
        default:
            return
        }
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "entryCell",
                                                       for: indexPath) as? FeedEntryTableViewCell else {
            fatalError("Could not dequeue cell")
        }
        configure(cell: cell, at: indexPath)
        return cell
    }

    func configure(cell: FeedEntryTableViewCell, at indexPath: IndexPath) {
        let feedEntry = fetchedResultsController.object(at: indexPath)
        cell.feedEntry = feedEntry
    }
    
    // method to run when table view cell is tapped
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
           
           // Segue to the second view controller
           self.performSegue(withIdentifier: "showDetails", sender: self)
       }
        
    @IBAction func onRefreshPull(_ sender: UIRefreshControl) {
        fetchLatestEntries(sender)
    }
    
    func fetchLatestEntries(_ sender: UIRefreshControl? = nil){
        sender?.beginRefreshing()

        // update local DB
        let queue = OperationQueue()
        queue.qualityOfService = .userInitiated
        queue.maxConcurrentOperationCount = 1

        let context = PersistentContainer.shared.newBackgroundContext()
        let operations = Operations.getOperationsToFetchLatestEntries(using: context, server: server)
        operations.last?.completionBlock = {
            DispatchQueue.main.async {
                sender?.endRefreshing()
            }
        }
        queue.addOperations(operations, waitUntilFinished: false)
    }
    
    
    @IBAction private func showActions(_ sender: UIBarButtonItem) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.popoverPresentationController?.barButtonItem = sender

        let deleteText = NSLocalizedString("Delete all stored data", comment: "You want to delete all data")
        alertController.addAction(UIAlertAction(title: deleteText, style: .destructive, handler: { _ in
            PersistentContainer.shared.deleteAllStoredData()
//            PersistentContainer.shared.loadInitialData(onlyIfNeeded: false)
        }))
        
        let cancelText =  NSLocalizedString("Cancel", comment: "Quit")
        alertController.addAction(UIAlertAction(title: cancelText, style: .cancel, handler: nil))

        present(alertController, animated: true, completion: nil)
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetails" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let object = fetchedResultsController.object(at: indexPath)
                let controller = segue.destination as! DetailsViewController
                controller.feedEntry = object
                controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
                controller.navigationItem.leftItemsSupplementBackButton = true
            }
        }
    }
    
    
    func getTitleView(titleText: String, imageName: String) -> UIView {

        // Creates a new UIView
        let titleView = UIView()

        // Creates a new text label
        let label = UILabel()
        label.text = titleText
        label.sizeToFit()
        label.center = titleView.center
        label.textAlignment = NSTextAlignment.center

        // Creates the image view
        let image = UIImageView()
        image.image = UIImage(named: imageName)

        // Maintains the image's aspect ratio:
        let imageAspect = image.image!.size.width / image.image!.size.height

        // Sets the image frame so that it's immediately before the text:
        let imageX = label.frame.origin.x - label.frame.size.height * imageAspect
        let imageY = label.frame.origin.y

        let imageWidth = label.frame.size.height * imageAspect
        let imageHeight = label.frame.size.height

        image.frame = CGRect(x: imageX, y: imageY, width: imageWidth, height: imageHeight)

        image.contentMode = UIView.ContentMode.scaleAspectFit

        // Adds both the label and image view to the titleView
        titleView.addSubview(label)
        titleView.addSubview(image)

        // Sets the titleView frame to fit within the UINavigation Title
        titleView.sizeToFit()

        return titleView
    }
    
}


