//
//  RatioImageCVCell.swift
//  BeautyEditor
//
//  Created by Peter.M on 02/04/2019.
//

import UIKit

class RatioImageCVCell: UICollectionViewCell {
    @IBOutlet weak var imageView:UIImageView!
    override var isSelected: Bool {
        didSet{
            self.imageView.tintColor = isSelected ? .white : .gray
        }
    }
}
