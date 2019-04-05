//
//  GuideManager.swift
//  BeautyEditor
//
//  Created by Peter.M on 04/04/2019.
//  Copyright © 2019 HASYS. All rights reserved.
//

import UIKit

/// 대상 뷰에 딤된 레이어에 마스킹뷰를 조절할 수 있는 뷰를 생성 및 관리
class GuideManager:NSObject {
    
    ///드레그용 점View. 터치영역을 위해 점은 실제로 뷰보다 작음
    class DotView:UIView {
        let dotImageView:UIImageView
        /// 초기화..
        /// - parameter dotSize: 점 싸이즈
        /// - parameter insets: 점 주변 여백 사이즈(이거 랑 점 싸이즈 더하면 실제 프레임 사이즈)
        init(dotSize:CGSize, insets:UIEdgeInsets) {
            self.dotImageView = UIImageView()
            let rect = CGRect(x: 0, y: 0, width: dotSize.width + insets.left + insets.right, height: dotSize.height + insets.top + insets.bottom)
            super.init(frame: rect)
            self.dotImageView.backgroundColor = .white
            self.dotImageView.frame.size = dotSize
            self.dotImageView.frame.origin = CGPoint(x: insets.left, y: insets.top)
            self.addSubview(self.dotImageView)
            self.backgroundColor = .clear
            self.dotImageView.layer.masksToBounds = true
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            self.dotImageView.layer.cornerRadius = self.dotImageView.layer.frame.size.width / 2
        }
    }
    
    /// 사각형 실제 영역
    var targetRect:CGRect {
        get{
            return self.realMaskRect
        }
        set{
            guard let targetView = self.targetView else{return}
            self.targetInsets = UIEdgeInsets(
                top: newValue.minY / targetView.frame.height
                , left: newValue.minX / targetView.frame.width
                , bottom: 1 - newValue.maxY / targetView.frame.height
                , right: 1 - newValue.maxX / targetView.frame.width
            )
        }
    }
    
    /// 사각형의 여백 가장자리 여백 퍼센테이지 정보(값:0~1.0)
    var targetInsets:UIEdgeInsets = UIEdgeInsets(top: 0.1, left: 0.1, bottom: 0.1, right: 0.1) {
        didSet{
            self.updateScrollViewInsets()
        }
    }
    /// 선택가능 Rect의 가장자리 여백 사이즈
    var selectableInsets:UIEdgeInsets = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
    /// 선택가능의 실제 frame
    var selectableRect:CGRect {
        get {
            guard let targetView = self.targetView else{return .zero}
            return CGRect(
                x: self.selectableInsets.left
                , y: self.selectableInsets.top
                , width: targetView.frame.width - self.selectableInsets.left - self.selectableInsets.right
                , height: targetView.frame.height - self.selectableInsets.top - self.selectableInsets.bottom
            )
        }
    }
    /// 비율 제한 (가로 / 세로)
    var limitRatio:CGFloat?
    /// 점 지름
    let dotDiameter:CGFloat = 14
    /// 드레그 점(순서대로.. 좌상, 우상, 우하, 좌하)
    var dotViews:[DotView] = []
    /// 가이드 라인(순서대로.. 좌,상,우,하)
    var lineViews:[UIView] = []
    /// dim된 화면의 가운대 뚤린 뷰
    let focusView:FocusView
    /// 최소 영역 크기
    var minimumSize:CGSize {
        if let limitRatio = self.limitRatio {
            if limitRatio > 1 {
                return CGSize(width: _minimumSize.width, height: _minimumSize.width / limitRatio)
            }else{
                return CGSize(width: _minimumSize.height * limitRatio, height: _minimumSize.height)
            }
        }else{
            return _minimumSize
        }
    }
    let _minimumSize:CGSize = CGSize(width: 80, height: 80)
    /// 요소를 addsubview할 뷰
    weak var targetView:UIView?
    /// insets 업데이트 받을 스크롤 뷰(드레그 시)
    weak var scrollView:UIScrollView?
    /// 초기화
    /// - parameter targetView: 요소를 addSubView 할 뷰
    /// - parameter scrollView: insets 업데이트 받을 스크롤 뷰(드레그 시)
    init(targetView:UIView, scrollView:UIScrollView? = nil) {
        self.targetView = targetView
        self.scrollView = scrollView
        self.focusView = FocusView()
        super.init()
        targetView.addSubview(self.focusView)
        /// 버튼 터치 확장 영역
        let insets = UIEdgeInsets(
            top: 10
            , left: 10
            , bottom: 10
            , right: 10
        )
        (0..<4).forEach { _ in
            dotViews.append(GuideManager.DotView(dotSize: CGSize(width: dotDiameter, height: dotDiameter), insets: insets))
            lineViews.append(UIView(frame: .zero))
        }
        lineViews.forEach { (view) in
            view.backgroundColor = UIColor.white
            self.targetView?.addSubview(view)
        }
        dotViews.forEach { (view) in
            let panGR = UIPanGestureRecognizer(target: self, action: #selector(panAction(panGR:)))
            view.addGestureRecognizer(panGR)
            self.targetView?.addSubview(view)
        }
        
    }
    /// 점 드레그 시 화면을 업데이트해야한다.
    @objc func panAction(panGR:UIPanGestureRecognizer) {
        guard let targetView = self.targetView else{return}
        var location = panGR.location(in: targetView)
        guard let view = panGR.view else{return}
        func setupLeft(){
            let maxLeft = 1 - (targetView.frame.width * self.targetInsets.right + minimumSize.width) / targetView.frame.width
            targetInsets.left = min(maxLeft, max(location.x / targetView.frame.width, self.selectableInsets.left / targetView.frame.width))
        }
        func setupRight(){
            let maxRight = 1 - (targetView.frame.width * self.targetInsets.left + minimumSize.width) / targetView.frame.width
            targetInsets.right = min(maxRight, max(1 - location.x / targetView.frame.width, self.selectableInsets.right / targetView.frame.width))
        }
        func setupBottom(){
            let maxBottom = 1 - (targetView.frame.height * self.targetInsets.top + minimumSize.height) / targetView.frame.height
            targetInsets.bottom = min(maxBottom, max(1 - location.y / targetView.frame.height, self.selectableInsets.bottom / targetView.frame.height))
        }
        func setupTop(){
            let maxTop = 1 - (targetView.frame.height * self.targetInsets.bottom + minimumSize.height) / targetView.frame.height
            targetInsets.top = min(maxTop, max(location.y / targetView.frame.height, self.selectableInsets.top / targetView.frame.height))
        }
        
        if location.x < self.selectableRect.minX {
            location.x = self.selectableRect.minX
        }else if location.x > self.selectableRect.maxX {
            location.x = self.selectableRect.maxX
        }
        
        if location.y < self.selectableRect.minY {
            location.y = self.selectableRect.minY
        }else if location.y > self.selectableRect.maxY {
            location.y = self.selectableRect.maxY
        }
        
        switch view {
        case self.dotViews[0]:
            if let ratio = self.limitRatio {
                let distanceX = self.dotViews[2].center.x - location.x
                let distanceY = self.dotViews[2].center.y - location.y
                if abs(distanceX) * ratio < abs(distanceY) {
                    location.y = self.dotViews[2].center.y - distanceX / ratio
                }else{
                    location.x = self.dotViews[2].center.x - distanceY * ratio
                }
            }
            setupLeft()
            setupTop()
        case self.dotViews[1]:
            if let ratio = self.limitRatio {
                let distanceX = self.dotViews[3].center.x - location.x
                let distanceY = self.dotViews[3].center.y - location.y
                if abs(distanceX) * ratio < abs(distanceY) {
                    location.y = self.dotViews[3].center.y + distanceX / ratio
                }else{
                    location.x = self.dotViews[3].center.x + distanceY * ratio
                }
            }
            
            setupTop()
            setupRight()
        case self.dotViews[2]:
            if let ratio = self.limitRatio {
                let distanceX = self.dotViews[0].center.x - location.x
                let distanceY = self.dotViews[0].center.y - location.y
                if abs(distanceX) * ratio < abs(distanceY) {
                    location.y = self.dotViews[0].center.y - distanceX / ratio
                }else{
                    location.x = self.dotViews[0].center.x - distanceY * ratio
                }
            }
            setupRight()
            setupBottom()
        case self.dotViews[3]:
            if let ratio = self.limitRatio {
                let distanceX = self.dotViews[1].center.x - location.x
                let distanceY = self.dotViews[1].center.y - location.y
                if abs(distanceX) * ratio < abs(distanceY) {
                    location.y = self.dotViews[1].center.y + distanceX / ratio
                }else{
                    location.x = self.dotViews[1].center.x + distanceY * ratio
                }
            }
            setupBottom()
            setupLeft()
        default:
            ();
        }
        self.updateView()
        self.updateScrollViewInsets()
    }
    
    /// 스크롤뷰에 insets 업데이트
    func updateScrollViewInsets() {
        guard let targetView = self.targetView else{return}
        scrollView?.contentInset = UIEdgeInsets(
            top: self.targetRect.minY
            , left: self.targetRect.minX
            , bottom: targetView.frame.height - self.targetRect.maxY
            , right: targetView.frame.width - self.targetRect.maxX
        )
    }
    
    /// 점과 선과 구멍뷰 업데이트
    func updateView(){
        let maskRect = self.realMaskRect
        
        dotViews[0].center = CGPoint(x: maskRect.minX, y: maskRect.minY)
        dotViews[1].center = CGPoint(x: maskRect.maxX, y: maskRect.minY)
        dotViews[2].center = CGPoint(x: maskRect.maxX, y: maskRect.maxY)
        dotViews[3].center = CGPoint(x: maskRect.minX, y: maskRect.maxY)
        
        lineViews[0].center.x = maskRect.minX
        lineViews[0].frame.size.width = 1
        lineViews[0].frame.size.height = maskRect.height
        lineViews[0].frame.origin.y = maskRect.minY
        
        lineViews[1].center.y = maskRect.minY
        lineViews[1].frame.size.width = maskRect.width
        lineViews[1].frame.size.height = 1
        lineViews[1].frame.origin.x = maskRect.minX
        
        lineViews[2].center.x = maskRect.maxX
        lineViews[2].frame.size.width = 1
        lineViews[2].frame.size.height = maskRect.height
        lineViews[2].frame.origin.y = maskRect.minY
        
        lineViews[3].center.y = maskRect.maxY
        lineViews[3].frame.size.width = maskRect.width
        lineViews[3].frame.size.height = 1
        lineViews[3].frame.origin.x = maskRect.minX
        self.focusView.frame = self.targetView!.bounds
        self.focusView.targetInsets = self.targetInsets
    }
    
    /// rect기준으로 크롭핑영역 Rect
    var realMaskRect: CGRect {
        guard let rect = self.targetView?.bounds else{return .zero}
        return CGRect(
            x: rect.width * targetInsets.left
            , y: rect.height * targetInsets.top
            , width: rect.width * (1 - targetInsets.left - targetInsets.right)
            , height: rect.height * (1 - targetInsets.top - targetInsets.bottom)
        )
    }
}

/// 구멍 뚤린 뷰
class FocusView:UIView {
    /// 사각형의 여백 가장자리 여백 퍼센테이지 정보(값:0~1.0)
    var targetInsets:UIEdgeInsets = UIEdgeInsets(top: 0.1, left: 0.1, bottom: 0.1, right: 0.1) {
        didSet{
            self.setNeedsDisplay()
        }
    }
    /// 어둑한 뷰
    let dimView = UIView(frame: .zero)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.dimView.backgroundColor = UIColor.black
        self.dimView.alpha = 0.5
        self.isUserInteractionEnabled = false
        self.addSubview(dimView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.dimView.frame = self.bounds
    }
    
    override func draw(_ rect: CGRect) {
        let outsidePath = UIBezierPath(rect: CGRect(origin: .zero, size: rect.size))
        let insidePath = UIBezierPath(rect: realMaskRect(rect))
        outsidePath.append(insidePath)
        outsidePath.usesEvenOddFillRule = true
        let fillLayer = CAShapeLayer()
        fillLayer.path = outsidePath.cgPath
        fillLayer.fillRule = .evenOdd
        fillLayer.fillColor = UIColor.black.cgColor
        fillLayer.opacity = 0.5
        self.dimView.layer.mask = fillLayer
    }
    
    /// rect기준으로 크롭핑영역 Rect
    func realMaskRect(_ rect:CGRect) -> CGRect {
        return CGRect(
            x: rect.width * targetInsets.left
            , y: rect.height * targetInsets.top
            , width: rect.width * (1 - targetInsets.left - targetInsets.right)
            , height: rect.height * (1 - targetInsets.top - targetInsets.bottom)
        )
    }
    
    
}

