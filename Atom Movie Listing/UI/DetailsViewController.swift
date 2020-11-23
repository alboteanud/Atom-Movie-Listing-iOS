//
//  DetailsViewController.swift
//  Atom Movie Listing
//
//  Created by Dan Alboteanu on 21.11.2020.
//

import UIKit

class DetailsViewController: UIViewController {
    
    var listEntry: FeedEntry!
    let server = MovieServer()
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var overviewLabel: UILabel!
    @IBOutlet weak var mImageView: UIImageView!
    @IBOutlet weak var productionCompaniesLabel: UILabel!
    @IBOutlet weak var categoryLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if listEntry == nil {
            print("invalid entry")
            return
        }
        
        configureViews()
        
        server.fetchServerEntry(entryId: listEntry.id){result in
            DispatchQueue.main.async {
                self.updateViews(detailedEntry: result)
            }
        }?.resume()
    }
    
    func configureViews(){
        titleLabel.text = listEntry.title
        overviewLabel.text = listEntry.overview
        server.fetchImage(listEntry.poster_path){ image in
            DispatchQueue.main.async {
                self.mImageView.image = image ?? UIImage(named: "PlaceholderMovie")
            }
        }?.resume()
    }
    
    func updateViews(detailedEntry: ServerEntryResult?){
        guard let entry = detailedEntry else { return}
        
        titleLabel.text = entry.title
        if let genresNames = entry.genres?.compactMap({$0.name}){
            let genresString = genresNames.joined(separator: " | ")
            categoryLabel.text = genresString
        }
        if let companyNames = entry.production_companies?.compactMap({$0.name}){
            let joinedCompaniesString = companyNames.joined(separator: ", ")
            if joinedCompaniesString != "" {
                productionCompaniesLabel.text = joinedCompaniesString + "."
            }
            // else hide productin frame
            
        }
        
        
    }
    
    
    
}
