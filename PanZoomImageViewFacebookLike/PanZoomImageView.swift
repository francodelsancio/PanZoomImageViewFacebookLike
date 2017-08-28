//
//  PanZoomImageView.swift
//
//
//  Created by Franco Del Sancio on 16/8/17.
//  Copyright © 2017 Franco Del Sancio. All rights reserved.
//

import UIKit

extension UIImageView {
    func addZoomGesture() {
        self.isUserInteractionEnabled = true
        let gesture = UITapGestureRecognizer(target: self, action: #selector(UIImageView.zoom))
        self.addGestureRecognizer(gesture)
    }
    internal func zoom(tapGesture: UITapGestureRecognizer) {
        if let imageView = tapGesture.view as? UIImageView {
            guard let image = imageView.image else {return}
            PanZoomImageView.shared.PerfoZoomForStardingImageView(imageView: imageView, imageWidth: image.size.width, imageHeight: image.size.height)
        }
    }
    
}


class PanZoomImageView: NSObject, UIScrollViewDelegate {
    
    //MARK: properties
    
    private var StartingImageview: UIImageView!
    private var zoomingImagView: UIImageView!
    private var cornerRadiusState: CGFloat?
    private let BlackBackground = UIView()
    private var startingFrame = CGRect()
    private let ScrollViewImages = UIScrollView()
    private var orientation: UIDeviceOrientation!
    
    static let shared: PanZoomImageView = {
        let instance = PanZoomImageView()
        return instance
    }()
    
    
    /**
     Add functionality to the ImageView to expand the image to full screen by adding zoom - pan - scroll with animated return to the origin. Device rotation supported.
     - parameter imageView: UIImageView to Pan-Zoom.
     - parameter imageWidth:  If these parameters are nil the image is square.
     - parameter imageHeight: If these parameters are nil the image is square.
     */
    
    func PerfoZoomForStardingImageView(imageView: UIImageView,imageWidth: CGFloat?,imageHeight: CGFloat?) {
        
        guard let window = UIApplication.shared.keyWindow else {return}
        
        guard imageView.image != nil else {return}
        
        guard let starting = imageView.superview else {return}
        
        // save orientation
        orientation = UIDevice.current.orientation
        // sabe corner radius
        cornerRadiusState = imageView.layer.cornerRadius
        
        let startingFrames = starting.convert(imageView.frame, to: nil)
        
        startingFrame = startingFrames
        StartingImageview = imageView
        StartingImageview.isHidden = true
        
        zoomingImagView = UIImageView(frame: startingFrames) // StartFrame
        zoomingImagView.layer.cornerRadius = cornerRadiusState != nil ? cornerRadiusState! : 0
        zoomingImagView.layer.masksToBounds = cornerRadiusState != nil
        
        setupViews()
        
        window.addSubview(zoomingImagView)
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations:{
            
            let width = window.frame.width < window.frame.height ? window.frame.width : window.frame.height
            
            let height: CGFloat = imageWidth != nil ? imageHeight! / imageWidth! * width :  self.startingFrame.height / self.startingFrame.width * width
            
            self.zoomingImagView.bounds = CGRect(x: window.center.x, y: window.center.y, width: width, height: height)
            
            self.zoomingImagView.layer.cornerRadius = 0
            self.zoomingImagView.layer.masksToBounds = false
            self.BlackBackground.backgroundColor = UIColor(white: 0, alpha: 1)
            
            self.zoomingImagView.center = window.center
            
            self.zoomingImagView.layoutIfNeeded()
            
        }, completion: {[weak myself = self] (completion) in
            
            myself?.setupViewAfterZoom()
            
        })
        
    }
    
    private func setupViews() {
        guard let window = UIApplication.shared.keyWindow else {return}
        
        zoomingImagView.image = StartingImageview.image
        zoomingImagView.isUserInteractionEnabled = true
        zoomingImagView.contentMode = .scaleAspectFill
        zoomingImagView.clipsToBounds = true
        zoomingImagView.autoresizingMask = [.flexibleTopMargin, .flexibleBottomMargin, .flexibleRightMargin, .flexibleLeftMargin]
        
        window.addSubview(BlackBackground)
        BlackBackground.translatesAutoresizingMaskIntoConstraints = false
        BlackBackground.centerXAnchor.constraint(equalTo: window.centerXAnchor).isActive = true
        BlackBackground.centerYAnchor.constraint(equalTo: window.centerYAnchor).isActive = true
        BlackBackground.widthAnchor.constraint(equalTo: window.widthAnchor).isActive = true
        BlackBackground.heightAnchor.constraint(equalTo: window.heightAnchor).isActive = true
        BlackBackground.backgroundColor = UIColor(white: 0, alpha: 0)
        BlackBackground.addSubview(ScrollViewImages)
        
        ScrollViewImages.backgroundColor = UIColor.clear
        ScrollViewImages.flashScrollIndicators()
        ScrollViewImages.delegate = self
        ScrollViewImages.autoresizingMask = [UIViewAutoresizing.flexibleWidth, UIViewAutoresizing.flexibleHeight]
        ScrollViewImages.contentSize = self.zoomingImagView.bounds.size
    }
    
    //MARK: scrollView Methods
    
    internal func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return zoomingImagView
    }
    
    internal func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerScrollViewContents()
    }
    
    
    private func setupViewAfterZoom() {
        zoomingImagView.removeFromSuperview()
        ScrollViewImages.addSubview(self.zoomingImagView)
        zoomingImagView.center = self.ScrollViewImages.center
        setZoomScale()
        setupGestureRecognizer()
        ScrollViewImages.setNeedsLayout()
        let pangesture = UIPanGestureRecognizer(target: self, action: #selector(PanZoomImageView.setupPanGesture))
        zoomingImagView.addGestureRecognizer(pangesture)
    }
    
    
    private func updateMinZoomScaleForSize(size: CGSize) {
        let widthScale = size.width / zoomingImagView.bounds.width
        let heightScale = size.height / zoomingImagView.bounds.height
        let minScale = min(widthScale, heightScale)
        ScrollViewImages.minimumZoomScale = minScale
        ScrollViewImages.zoomScale = minScale
    }
    
    private func setZoomScale() {
        let imageViewSize = zoomingImagView.bounds.size
        let scrollViewSize = ScrollViewImages.bounds.size
        let widthScale = scrollViewSize.width / imageViewSize.width
        let heightScale = scrollViewSize.height / imageViewSize.height
        ScrollViewImages.minimumZoomScale = min(widthScale, heightScale)
        ScrollViewImages.maximumZoomScale = 3.0
        ScrollViewImages.zoomScale = 1.0
        
    }
    
    private func centerScrollViewContents() {
        
        //center contents
        let boundsSize = ScrollViewImages.bounds.size
        var contentsFrame:CGRect = zoomingImagView!.frame
        
        if (contentsFrame.size.width < boundsSize.width) {
            contentsFrame.origin.x = (boundsSize.width - contentsFrame.size.width) / 2.0
        } else {
            contentsFrame.origin.x = 0.0
        }
        
        if (contentsFrame.size.height < boundsSize.height) {
            contentsFrame.origin.y = (boundsSize.height - contentsFrame.size.height) / 2.0
        } else {
            contentsFrame.origin.y = 0.0
        }
        
        zoomingImagView?.frame = contentsFrame
    }
    
    
    private func setupGestureRecognizer() {
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(PanZoomImageView.handleDoubleTap))
        doubleTap.numberOfTapsRequired = 2
        zoomingImagView!.addGestureRecognizer(doubleTap)
    }
    
    internal func handleDoubleTap(recognizer: UITapGestureRecognizer) {
        
        if (ScrollViewImages.zoomScale > ScrollViewImages.minimumZoomScale) {
            ScrollViewImages.setZoomScale(ScrollViewImages.minimumZoomScale, animated: true)
        } else {
            ScrollViewImages.setZoomScale(ScrollViewImages.maximumZoomScale, animated: true)
        }
    }
    
    internal func setupPanGesture(gesture: UIPanGestureRecognizer) {
        let localizacion = gesture.translation(in: zoomingImagView)
        let x:CGFloat = gesture.view!.center.x + localizacion.x
        let y:CGFloat = gesture.view!.center.y + localizacion.y
        
        gesture.view!.center = CGPoint(x: x, y: y)
        gesture.setTranslation(CGPoint.zero, in: zoomingImagView)
        
        switch gesture.state {
        case .began :
            
            UIView.animate(withDuration: 0.5, animations: {
                self.BlackBackground.backgroundColor = UIColor(white: 0, alpha: 0.5)
            })
            
        case .changed :
            
            zoomingImagView.layer.masksToBounds = false
            zoomingImagView.layer.shadowColor = UIColor.black.cgColor
            zoomingImagView.layer.shadowOpacity = 0.8
            zoomingImagView.layer.shadowOffset = CGSize.zero
            zoomingImagView.layer.shadowRadius = 5
            zoomingImagView.layer.shadowPath = UIBezierPath(rect: zoomingImagView.bounds).cgPath
            
        case .ended :
            
            guard let view = gesture.view else {return}
            guard let window = UIApplication.shared.keyWindow else {return}
            let centro = window.center
            let pointer:CGFloat = 60
            
            let rect = CGRect(x: centro.x - pointer / 2, y: centro.y - pointer / 2, width: pointer, height: pointer)
            
            if !rect.contains(view.center) {
                
                self.goBack()
                
            } else {
                UIView.animate(withDuration: 0.5, delay: 0.1, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.8, options: .curveEaseOut, animations: { [weak selfWeak = self] in
                    selfWeak?.zoomingImagView.layer.shadowColor = UIColor.clear.cgColor
                    gesture.view!.center = CGPoint(x: window.center.x, y: window.center.y)
                    DispatchQueue.main.async {
                        selfWeak?.BlackBackground.backgroundColor = UIColor(white: 0, alpha: 1)
                    }
                    
                })
                
            }
            
        default:
            print("not set")
        }
        
    }
    
    //MARK: goBack Method
    
    fileprivate func goBack() {
        
        
        if orientation != UIDevice.current.orientation {
            // return to original orientation
            UIDevice.current.setValue(orientation.rawValue, forKey: "orientation")
            StartingImageview.isHidden = true
        }
        
        UIView.animate(withDuration: 0.5, delay: 0.1, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.9, options: .curveEaseOut, animations: {
            
            self.goBackAnimation()
            
        }, completion: { [weak myself = self] (_) in
            myself?.StartingImageview.isHidden = false
            UIView.animate(withDuration: 0.5, animations: { [weak myself = self] in
                myself?.zoomingImagView.alpha = 0
                }, completion: { (_) in
                    myself?.zoomingImagView.removeFromSuperview()
                    myself?.ScrollViewImages.removeFromSuperview()
                    myself?.BlackBackground.removeFromSuperview()
            })
            
        })
        
    }
    
    fileprivate func goBackAnimation() {
        self.BlackBackground.backgroundColor = UIColor(white: 0, alpha: 0)
        self.zoomingImagView.layer.cornerRadius = self.cornerRadiusState != nil ? self.cornerRadiusState! : 0
        self.zoomingImagView.layer.masksToBounds = self.cornerRadiusState != nil
        self.ScrollViewImages.zoomScale = 1.0
        self.zoomingImagView.frame = self.startingFrame
        self.zoomingImagView.layer.shadowColor = UIColor.clear.cgColor
        self.zoomingImagView.layoutIfNeeded()
        
    }
    
    
}
