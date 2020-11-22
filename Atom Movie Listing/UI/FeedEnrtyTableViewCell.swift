//
//  FeedEnrtyTableViewCell.swift
//  Atom Movie Listing
//
//  Created by Dan Alboteanu on 20.11.2020.
//

import UIKit

class FeedEntryTableViewCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var myImageView: UIImageView!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    var feedEntry: FeedEntry? {
        didSet {
            updateCell()
        }
    }
    
    private func updateCell() {
//        guard let firstColor = feedEntry?.firstColor,
//            let secondColor = feedEntry?.secondColor,
//            let gradientDirection = feedEntry?.gradientDirection,
//            let timestamp = feedEntry?.timestamp else {
//                return
//            }
//
//        colorView.parameters = ColorView.Parameters(firstColor: UIColor(firstColor),
//                                                    secondColor: UIColor(secondColor),
//                                                    gradientDirection: gradientDirection,
//                                                    text: timestamp.shortDescription)
      
        titleLabel.text = feedEntry?.title
        descriptionLabel.text = feedEntry?.overview
        myImageView.loadImageUsingUrlString(posterPath: feedEntry?.poster_path)
    }
}

extension UIImageView {
    
    func loadImageUsingUrlString(posterPath: String? , contentMode mode: UIView.ContentMode = .scaleAspectFit) {
        
        guard let posterPath = posterPath else { return }
        guard let url = MockServer().buildPhotoDownloadUrl(photoPath: posterPath) else { return}
        
        URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
            guard
                let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
                let data = data, error == nil,
                let image = UIImage(data: data)
            else { return }
            
            DispatchQueue.main.async { 
                self.image = image
            }
            return
            
        }).resume()
    }
}
