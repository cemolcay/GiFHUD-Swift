//
//  GiFHUD.swift
//  GiFHUD-Swift
//
//  Created by Cem Olcay on 07/11/14.
//  Copyright (c) 2014 Cem Olcay. All rights reserved.
//

import UIKit
import ImageIO
import MobileCoreServices


// MARK: - UIImageView Extension

extension UIImageView {
    
    // MARK: Computed Properties
    
    var animatableImage: AnimatedImage? {
        if image is AnimatedImage {
            return image as? AnimatedImage
        } else {
            return nil
        }
    }
    
    var isAnimatingGif: Bool {
        return animatableImage?.isAnimating() ?? false
    }
    
    var animatable: Bool {
        return animatableImage != nil
    }
    
    
    // MARK: Method Overrides
    override open func display(_ layer: CALayer) {
        if let image = animatableImage {
            if let frame = image.currentFrame {
                layer.contents = frame.cgImage
            }
        }
    }
    
    
    // MARK: Setter Methods
    
    func setAnimatableImage(named name: String) {
        image = AnimatedImage.imageWithName(name, delegate: self)
        layer.setNeedsDisplay()
    }
    
    func setAnimatableImage(data: Data) {
        image = AnimatedImage.imageWithData(data, delegate: self)
        layer.setNeedsDisplay()
    }
    
    
    // MARK: Animation
    
    func startAnimatingGif() {
        if animatable {
            animatableImage!.resumeAnimation()
        }
    }
    
    func stopAnimatingGif() {
        if animatable {
            animatableImage!.pauseAnimation()
        }
    }
    
}


// MARK: - UIImage Extension

class AnimatedImage: UIImage {
    
    func CGImageSourceContainsAnimatedGIF(_ imageSource: CGImageSource) -> Bool {
        let isTypeGIF = UTTypeConformsTo(CGImageSourceGetType(imageSource)!, kUTTypeGIF)
        let imageCount = CGImageSourceGetCount(imageSource)
        return isTypeGIF != false && imageCount > 1
    }
    
    func CGImageSourceGIFFrameDuration(_ imageSource: CGImageSource, index: Int) -> TimeInterval {
        let containsAnimatedGIF = CGImageSourceContainsAnimatedGIF(imageSource)
        if !containsAnimatedGIF { return 0.0 }
        
        var duration = 0.0
        if let imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, Int(index), nil) as? [String: Any],
            let GIFProperties = imageProperties[String(kCGImagePropertyGIFDictionary)] as? [String: Any] {
            
            duration = (GIFProperties[String(kCGImagePropertyGIFUnclampedDelayTime)] as? Double) ?? 0
            if duration <= 0 {
                duration = (GIFProperties[String(kCGImagePropertyGIFDelayTime)] as? Double) ?? 0
            }
        }
        
        let threshold = 0.02 - Double(Float.ulpOfOne)
        if duration > 0 && duration < threshold {
            duration = 0.1
        }
        
        return duration
    }
    
    
    // MARK: Constants
    
    let framesToPreload = 10
    let maxTimeStep = 1.0
    
    
    // MARK: Public Properties
    
    var delegate: UIImageView?
    var frameDurations = [TimeInterval]()
    var frames = [UIImage?]()
    var totalDuration: TimeInterval = 0.0
    
    
    // MARK: Private Properties
    
    fileprivate lazy var displayLink: CADisplayLink = CADisplayLink(target: self, selector: #selector(updateCurrentFrame))
    fileprivate lazy var preloadFrameQueue: DispatchQueue! = DispatchQueue(label: "co.kaishin.GIFPreloadImages", attributes: [])
    fileprivate var currentFrameIndex = 0
    fileprivate var imageSource: CGImageSource?
    fileprivate var timeSinceLastFrameChange: TimeInterval = 0.0
    
    
    // MARK: Computed Properties
    
    var currentFrame: UIImage? {
        return frameAtIndex(currentFrameIndex)
    }
    
    fileprivate var isAnimated: Bool {
        return imageSource != nil
    }
    
    
    // MARK: Initializers
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    required init(data: Data, delegate: UIImageView?) {
        let imageSource = CGImageSourceCreateWithData(data as CFData, nil)
        self.delegate = delegate
        
        super.init()
        attachDisplayLink()
        prepareFrames(imageSource)
        pauseAnimation()
    }
    
    required convenience init(imageLiteral name: String) {
        fatalError("init(imageLiteral:) has not been implemented")
    }
    
    required convenience init(imageLiteralResourceName name: String) {
        fatalError("init(imageLiteralResourceName:) has not been implemented")
    }
    
    // MARK: Factories
    
    class func imageWithName(_ name: String, delegate: UIImageView?) -> Self? {
        let path = (Bundle.main.bundlePath as NSString).appendingPathComponent(name)
        let data = try? Data (contentsOf: Foundation.URL(fileURLWithPath: path))
        return (data != nil) ? imageWithData(data!, delegate: delegate) : nil
    }
    
    class func imageWithData(_ data: Data, delegate: UIImageView?) -> Self? {
        return self.init(data: data, delegate: delegate)
    }
    
    
    // MARK: Display Link Helpers
    
    func attachDisplayLink() {
        displayLink.add(to: RunLoop.main, forMode: RunLoopMode.commonModes)
    }
    
    
    // MARK: Frame Methods
    
    fileprivate func prepareFrames(_ source: CGImageSource!) {
        imageSource = source
        
        let numberOfFrames = Int(CGImageSourceGetCount(self.imageSource!))
        frameDurations.reserveCapacity(numberOfFrames)
        frames.reserveCapacity(numberOfFrames)
        
        for index in 0..<numberOfFrames {
            let frameDuration = CGImageSourceGIFFrameDuration(source, index: index)
            frameDurations.append(frameDuration)
            totalDuration += frameDuration
            
            if index < framesToPreload {
                let frameImageRef = CGImageSourceCreateImageAtIndex(self.imageSource!, Int(index), nil)
                let frame = UIImage(cgImage: frameImageRef!, scale: 0.0, orientation: UIImageOrientation.up)
                frames.append(frame)
            } else {
                frames.append(nil)
            }
        }
    }
    
    func frameAtIndex(_ index: Int) -> UIImage? {
        if Int(index) >= self.frames.count { return nil }
        
        let image: UIImage? = self.frames[Int(index)]
        updatePreloadedFramesAtIndex(index)
        
        return image
    }
    
    fileprivate func updatePreloadedFramesAtIndex(_ index: Int) {
        if frames.count <= framesToPreload { return }
        
        if index != 0 {
            frames[index] = nil
        }
        
        for internalIndex in (index + 1)...(index + framesToPreload) {
            let adjustedIndex = internalIndex % frames.count
            
            if frames[adjustedIndex] == nil {
                preloadFrameQueue.async {
                    let frameImageRef = CGImageSourceCreateImageAtIndex(self.imageSource!, Int(adjustedIndex), nil)
                    self.frames[adjustedIndex] = UIImage(cgImage: frameImageRef!)
                }
            }
        }
    }
    
    func updateCurrentFrame() {
        if !isAnimated { return }
        
        timeSinceLastFrameChange += min(maxTimeStep, displayLink.duration)
        let frameDuration = frameDurations[currentFrameIndex]
        
        while timeSinceLastFrameChange >= frameDuration {
            timeSinceLastFrameChange -= frameDuration
            currentFrameIndex += 1
            
            if currentFrameIndex >= frames.count {
                currentFrameIndex = 0
            }
            
            delegate?.layer.setNeedsDisplay()
        }
    }
    
    
    // MARK: Animation
    
    func pauseAnimation() {
        displayLink.isPaused = true
    }
    
    func resumeAnimation() {
        displayLink.isPaused = false
    }
    
    func isAnimating() -> Bool {
        return !displayLink.isPaused
    }
}


// MARK: - GiFHUD

class GiFHUD: UIView {
    
    // MARK: Constants
    
    let Size            : CGSize            = CGSize(width: 180, height: 140)
    let FadeDuration    : TimeInterval    = 0.3
    let GifSpeed        : CGFloat           = 0.3
    let OverlayAlpha    : CGFloat           = 0.3
    let Window          : UIWindow = (UIApplication.shared.delegate as! AppDelegate).window!
    
    
    // MARK: Variables
    
    var overlayView     : UIView?
    var imageView       : UIImageView?
    var shown           : Bool
    fileprivate var tapGesture: UITapGestureRecognizer?
    fileprivate var didTapClosure: (() -> Void)?
    fileprivate var swipeGesture: UISwipeGestureRecognizer?
    fileprivate var didSwipeClosure: (() -> Void)?
    
    // MARK: Singleton
    
    class var instance : GiFHUD {
        struct Static {
            static let inst : GiFHUD = GiFHUD()
        }
        return Static.inst
    }
    
    
    // MARK: Init
    
    init () {
        self.shown = false
        super.init(frame: CGRect (x: 0, y: 0, width: Size.width, height: Size.height))
        
        alpha = 0
        center = Window.center
        clipsToBounds = false
        layer.backgroundColor = UIColor(white: 0, alpha: 0.5).cgColor
        layer.cornerRadius = 10
        layer.masksToBounds = true
        
        imageView = UIImageView(frame: bounds.insetBy(dx: 20, dy: 20))
        addSubview(imageView!)

        Window.addSubview(self)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    // MARK: HUD
    
    class func showWithOverlay() {
        dismiss ({
            self.instance.Window.addSubview(self.instance.overlay())
            self.show()
        })
    }
    
    class func show() {
        dismiss({
            if let _ = self.instance.imageView?.animationImages {
                self.instance.imageView?.startAnimating()
            } else {
                self.instance.imageView?.startAnimatingGif()
            }
            
            self.instance.Window.bringSubview(toFront: self.instance)
            self.instance.shown = true
            self.instance.fadeIn()
        })
    }
    
    class func showForSeconds (_ seconds: Double) {
        show()
        let time = DispatchTime.now() + Double(Int64(seconds * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: time, execute: {
            GiFHUD.dismiss()
        })
    }
    
    class func dismissOnTap (_ didTap: (() -> Void)? = nil) {
        self.instance.tapGesture = UITapGestureRecognizer(target: self, action: #selector(userTapped))
        self.instance.addGestureRecognizer(self.instance.tapGesture!)
        self.instance.didTapClosure = didTap
    }
    
    @objc fileprivate class func userTapped () {
        GiFHUD.dismiss()
        self.instance.tapGesture = nil
        self.instance.didTapClosure?()
        self.instance.didTapClosure = nil
    }
    
    class func dismissOnSwipe (_ didTap: (() -> Void)? = nil) {
        self.instance.swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(userSwiped))
        self.instance.addGestureRecognizer(self.instance.swipeGesture!)
    }
    
    @objc fileprivate class func userSwiped () {
        GiFHUD.dismiss()
        self.instance.swipeGesture = nil
        self.instance.didSwipeClosure?()
        self.instance.didSwipeClosure = nil
    }
    
    class func dismiss () {
        if (!self.instance.shown) {
            return
        }
        
        self.instance.overlay().removeFromSuperview()
        self.instance.fadeOut()
        
        if let _ = self.instance.imageView?.animationImages {
            self.instance.imageView?.stopAnimating()
        } else {
            self.instance.imageView?.stopAnimatingGif()
        }
        self.instance.shown = false
    }
    
    class func dismiss (_ complate: @escaping ()->Void) {
        if (!self.instance.shown) {
            return complate ()
        }
        
        self.instance.fadeOut({
            self.instance.overlay().removeFromSuperview()
            complate ()
        })
        
        if let _ = self.instance.imageView?.animationImages {
            self.instance.imageView?.stopAnimating()
        } else {
            self.instance.imageView?.stopAnimatingGif()
        }
    }
    
    
    // MARK: Effects
    
    func fadeIn () {
        imageView?.startAnimatingGif()
        UIView.animate(withDuration: FadeDuration, animations: {
            self.alpha = 1
        })
    }
    
    func fadeOut () {
        UIView.animate(withDuration: FadeDuration, animations: {
            self.alpha = 0
        }, completion: { (complate) in
            self.shown = false
            self.imageView?.stopAnimatingGif()
        })
    }
    
    func fadeOut (_ complated: @escaping ()->Void) {
        UIView.animate(withDuration: FadeDuration, animations: {
            self.alpha = 0
        }, completion: { (complate) in
            self.shown = false
            self.imageView?.stopAnimatingGif()
            complated ()
        })
    }
    
    func overlay () -> UIView {
        if (overlayView == nil) {
            overlayView = UIView (frame: Window.frame)
            overlayView?.backgroundColor = UIColor.black
            overlayView?.alpha = 0
            
            UIView.animate(withDuration: 0.3, animations: { () -> Void in
                self.overlayView!.alpha = self.OverlayAlpha
            })
        }
        
        return overlayView!
    }
    
    
    // MARK: Gif
    
    class func setGif (_ name: String) {
        self.instance.imageView?.animationImages = nil
        self.instance.imageView?.stopAnimating()
        
        self.instance.imageView?.image = AnimatedImage.imageWithName(name, delegate: self.instance.imageView)
    }
    
    class func setGifBundle (_ bundle: Bundle) {
        self.instance.imageView?.animationImages = nil
        self.instance.imageView?.stopAnimating()
        
        self.instance.imageView?.image = AnimatedImage (data: try! Data(contentsOf: bundle.resourceURL!), delegate: nil)
    }
    
    class func setGifImages (_ images: [UIImage]) {
        self.instance.imageView?.stopAnimatingGif()
        
        self.instance.imageView?.animationImages = images
        self.instance.imageView?.animationDuration = TimeInterval(self.instance.GifSpeed)
    }
}
