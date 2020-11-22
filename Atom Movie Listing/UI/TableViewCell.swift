//
//  FeedEnrtyTableViewCell.swift
//  Atom Movie Listing
//
//  Created by Dan Alboteanu on 20.11.2020.
//

import UIKit

class TableViewCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var myImageView: UIImageView!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    var listEntry: ListEntry? {
        didSet {
            titleLabel.text = listEntry?.title
            descriptionLabel.text = listEntry?.overview
        }
    }
    var entryImage: UIImage? {
        didSet {
            DispatchQueue.main.async{
                self.myImageView.image = self.entryImage ?? UIImage(named: "PlaceholderMovie")
            }
        }
    }
}

// use this to add filter over the cached images
enum FilterType : String {
    case Chrome = "CIPhotoEffectChrome"
    case Fade = "CIPhotoEffectFade"
    case Instant = "CIPhotoEffectInstant"
    case Mono = "CIPhotoEffectMono"
    case Noir = "CIPhotoEffectNoir"
    case Process = "CIPhotoEffectProcess"
    case Tonal = "CIPhotoEffectTonal"
    case Transfer =  "CIPhotoEffectTransfer"
}

extension UIImage {
    func addFilter(filter : FilterType) -> UIImage {
        let filter = CIFilter(name: filter.rawValue)
        let ciInput = CIImage(image: self)
        filter?.setValue(ciInput, forKey: "inputImage")
        let ciOutput = filter?.outputImage
        let ciContext = CIContext()
        let cgImage = ciContext.createCGImage(ciOutput!, from: (ciOutput?.extent)!)
        return UIImage(cgImage: cgImage!)
    }
}
