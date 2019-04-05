//
//  ViewController.swift
//  BeautyEditor
//
//  Created by Peter on 04/02/2019.
//  Copyright (c) 2019 Peter. All rights reserved.
//

import UIKit
import BeautyEditor


class ViewController: UIViewController {

    @IBOutlet weak var getImageButton: UIButton!
    @IBOutlet weak var editRectButton: UIButton!
    var originalImage:UIImage?
    @IBAction func ibButtonAction(_ sender: UIButton) {
        switch sender {
        case getImageButton:
            let alertVC = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            alertVC.addAction(UIAlertAction(title: "Camera", style: .default, handler: { _ in
                self.getImage(type: .camera)
            }))
            alertVC.addAction(UIAlertAction(title: "Album", style: .default, handler: { _ in
                self.getImage(type: .photoLibrary)
            }))
            alertVC.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(alertVC, animated: true, completion: nil)
        case editRectButton:
            if let image = self.originalImage {
                self.goCrop(image: image)
            }
        default:
            ();
        }
    }
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    func getImage(type:UIImagePickerController.SourceType){
        let imagePickerVC = UIImagePickerController()
        imagePickerVC.allowsEditing = false
        imagePickerVC.sourceType = type
        if type == .camera {
            imagePickerVC.cameraCaptureMode = .photo
        }
        imagePickerVC.delegate = self
        imagePickerVC.dismiss(animated: true, completion: nil)
        self.present(imagePickerVC, animated: true, completion: nil)
    }
    
    func goCrop(image:UIImage) {
        let vc = CropViewController.instance(image: image)
        vc.delegate = self
        self.present(vc, animated: true, completion: nil)
    }
}


extension ViewController: CropViewControllerDelegate {
    func cropViewController(vc: CropViewController, didFinishWith originalImage: UIImage, cropedImage: UIImage) {
        self.imageView.image = cropedImage
        vc.dismiss(animated: true) {
            
        }
    }
}

extension ViewController: (UIImagePickerControllerDelegate & UINavigationControllerDelegate) {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true) {
            if let pickedImage = info[.originalImage] as? UIImage {
                self.originalImage = pickedImage
                self.goCrop(image: pickedImage)
            }
        }
        
    }
}

