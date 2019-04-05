//
//  CropViewController.swift
//  BeautyEditor
//
//  Created by Peter.M on 02/04/2019.
//

import UIKit
public protocol CropViewControllerDelegate:NSObjectProtocol {
    func cropViewController(vc:CropViewController, didFinishWith originalImage:UIImage, cropedImage:UIImage)
}
public class CropViewController: UIViewController {
    enum RatioType {
        case square/// 정사각형
        case rectangle /// 3:4
        
        /// 비율( 가로 / 세로 )
        var ratio:CGFloat {
            switch self {
            case .square:
                return 1
            case .rectangle:
                return 3 / 4
            }
        }
    }
    
    public class func instance(image:UIImage, preload frame:CGRect? = nil, zoomSacle:CGFloat? = nil) -> CropViewController {
        let vc = UIStoryboard(
            name: "Main"
            , bundle: Bundle(for: self)
            ).instantiateViewController(withIdentifier: "Crop") as! CropViewController
        vc.zoomImage = image
        return vc
    }
    
    /// 비율 선택
    @IBOutlet weak var collectionView: UICollectionView!
    /// 이미지 확대
    @IBOutlet weak var scrollView:UIScrollView!
    /// 이미지 확대 scrollView 및 크로핑 컨트롤러가 추가될
    @IBOutlet weak var containerView: UIView!
    /// 확인
    @IBOutlet weak var checkButton: UIButton!
    /// 선택가능한 비율 타입
    var ratioTypes:[RatioType] = [.square, .rectangle]
    
    var selectedRatioType:RatioType = .square
    var zoomImageView:UIImageView!
    var zoomImage:UIImage!
    var guideManager:GuideManager?
    public weak var delegate:CropViewControllerDelegate?
    public override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    @IBAction func ibButtonAction(_ sender: UIButton) {
        switch sender {
        case checkButton:
            guard let guideManager = self.guideManager else{return}
            if let imageView = self.zoomImageView, let image = imageView.image?.toPortrait() {
                let rect = self.containerView.convert(guideManager.targetRect, to: imageView)
                self.view.isUserInteractionEnabled = false
                if let cgImage = image.cgImage?.cropping(to: rect) {
                    UIGraphicsEndImageContext()
                    self.delegate?.cropViewController(vc: self, didFinishWith: self.zoomImage, cropedImage: UIImage(cgImage: cgImage))
                }
            }
        default:
            ();
        }
    }
    var path:UIBezierPath?
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.reloadImage()
        self.guideManager = GuideManager(targetView: self.containerView, scrollView:scrollView)
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.reloadImage()
        self.guideManager?.updateView()
        let contentWidth = self.collectionView.frame.width - 80
        self.collectionView.contentInset = UIEdgeInsets(top: 27, left: contentWidth / 2, bottom: 27, right: contentWidth / 2)
        
        
    }
    /// 가이드업데이트
    func updateGuideManager(){
        self.guideManager?.setRect(type: self.selectedRatioType)
        self.guideManager?.limitRatio = self.selectedRatioType.ratio
    }
    /// image를 기반으로 화면을 재정리
    func reloadImage(){
        guard let image = self.zoomImage else{return}
        let minInsets = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        var aspectInsets = minInsets
        let minimumViewSize = CGSize(
            width: (self.scrollView.frame.width - minInsets.left - minInsets.right)
            , height: self.scrollView.frame.height - minInsets.top - minInsets.bottom)
        
        let ratio = CGSize(width: minimumViewSize.width / image.size.width, height: minimumViewSize.height / image.size.height)
        if ratio.width < ratio.height {
            // 가로가 길때
            let height = self.scrollView.frame.height - minimumViewSize.width / image.size.width * image.size.height
            aspectInsets.top = height / 2
            aspectInsets.bottom = height / 2
        }else{
            let width = self.scrollView.frame.width - minimumViewSize.height / image.size.height * image.size.width
            aspectInsets.left = width / 2
            aspectInsets.right = width / 2
        }
        self.scrollView.contentInset = minInsets
        self.zoomImageView?.removeFromSuperview()
        self.zoomImageView = nil
        let imageView = UIImageView(image:self.zoomImage)
        imageView.isUserInteractionEnabled = true
        self.zoomImageView = imageView
        self.scrollView.addSubview(imageView)
        self.scrollView.maximumZoomScale = 10
        let viewSize = CGSize(
            width: (self.scrollView.frame.width - minInsets.left - minInsets.right)
            , height: self.scrollView.frame.height - minInsets.top - minInsets.bottom)
        self.scrollView.minimumZoomScale = max(viewSize.width / zoomImage.size.width, viewSize.height / zoomImage.size.height)
        self.scrollView.zoomScale = self.scrollView.minimumZoomScale
        self.scrollView.contentOffset = CGPoint(x: (self.scrollView.contentSize.width - self.zoomImageView.frame.width) / 2, y: (self.scrollView.contentSize.height - self.zoomImageView.frame.height) / 2)
        self.updateGuideManager()
        self.guideManager?.updateScrollViewInsets()
    }
}

extension CropViewController: UIScrollViewDelegate {
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.zoomImageView
    }
}

extension CropViewController: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.selectedRatioType = self.ratioTypes[indexPath.row]
        self.updateGuideManager()
        self.collectionView.reloadData()
    }
}
extension CropViewController: UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.ratioTypes.count
    }
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! RatioImageCVCell
        let type = self.ratioTypes[indexPath.row]
        cell.imageView.image = type.image
        cell.isSelected = self.selectedRatioType == type
        return cell
    }
}

fileprivate extension CropViewController.RatioType {
    var image:UIImage {
        return UIImage(named: self.imageFileName, in: Bundle(for: CropViewController.self), compatibleWith: nil)!.withRenderingMode(.alwaysTemplate)
    }
    var imageFileName:String {
        switch self {
        case .rectangle:
            return "btnCropRectangle"
        case .square:
            return "btnCropSquare"
        }
    }
}


extension GuideManager {
    func setRect(type:CropViewController.RatioType) {
        var rect = self.selectableRect
        let size = self.selectableRect.size
        
        switch type {
        case .square:
            if size.width > size.height {
                rect.size.width = size.height
                rect.origin.x += (size.width - size.height) / 2
            }else{
                rect.size.height = size.width
                rect.origin.y += (size.height - size.width) / 2
            }
            
            self.targetRect = rect
        case .rectangle:
            /// 가로 / 세로 비
            let ratio:CGFloat = 3 / 4
            if size.width > size.height / ratio {
                rect.size.width = size.height / 4 * 3
                rect.origin.x += (size.width - (size.height / 4 * 3)) / 2
            }else{
                rect.size.height = size.width / 3 * 4
                rect.origin.y = (size.height - rect.size.height) / 2
            }
            
            self.targetRect = rect
        }
        self.updateView()
    }
}
fileprivate extension UIImage {
    func toPortrait() -> UIImage? {
        UIGraphicsBeginImageContext(size)
        self.draw(in: CGRect(x: 0, y: 0,
                             width: size.width, height: size.height))
        let rotatedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return rotatedImage
    }
}
