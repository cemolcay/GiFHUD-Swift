//
//  GiFHUD.swift
//  GiFHUD-Swift
//
//  Created by Cem Olcay on 07/11/14.
//  Copyright (c) 2014 Cem Olcay. All rights reserved.
//

import UIKit
import ImageIO

class GiFHUD: UIView {
    
    // MARK: Constants
    
    let Size            : CGFloat = 150
    let FadeDuration    : NSTimeInterval = 0.3
    let GifSpeed        : CGFloat = 0.3
    let OverlayAlpha    : CGFloat = 0.3
    let Window          : UIWindow = (UIApplication.sharedApplication().delegate as AppDelegate).window!
    
    

    // MARK: Variables
    
    var overlayView     : UIView?
    var imageView       : UIImageView?
    var shown           : Bool
    
    
    
    // MARK: Singleton
    
    class var instance : GiFHUD {
        struct Static {
            static let inst : GiFHUD = GiFHUD ()
        }
        return Static.inst
    }
    
    

    // MARK: Init
    
    override init() {
        self.shown = false
        super.init(frame: CGRect (x: 0, y: 0, width: Size, height: Size))
        
        alpha = 0
        center = Window.center
        clipsToBounds = false
        layer.backgroundColor = UIColor (white: 0, alpha: 0.5).CGColor
        layer.cornerRadius = 10
        layer.masksToBounds = true
        
        imageView = UIImageView (frame: CGRectInset(bounds, 20, 20))
        addSubview(imageView!)
        Window.addSubview(self)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    
    
    // MARK: HUD
    
    class func showWithOverlay () {
        dismiss ({
            self.instance.Window.addSubview(self.instance.overlay())
            self.show()
        })
    }
    
    class func show () {
        dismiss({
            self.instance.Window.bringSubviewToFront(self.instance)
            self.instance.shown = true
            self.instance.fadeIn()
        })
    }
    
    class func dismiss () {
        if (!self.instance.shown) {
            return
        }
        
        self.instance.overlay().removeFromSuperview()
        self.instance.fadeOut()
    }
    
    class func dismiss (complate: ()->Void) {
        if (!self.instance.shown) {
            return complate ()
        }
        
        self.instance.fadeOut({
            self.instance.overlay().removeFromSuperview()
            complate ()
        })
    }
    
    
    
    // MARK: Effects
    
    func fadeIn () {
        imageView?.startAnimating()
        UIView.animateWithDuration(FadeDuration, animations: {
            self.alpha = 1
        })
    }
    
    func fadeOut () {
        UIView.animateWithDuration(FadeDuration, animations: {
            self.alpha = 0
            }, completion: { (complate) in
                self.shown = false
                self.imageView?.stopAnimating()
        })
    }
    
    func fadeOut (complated: ()->Void) {
        UIView.animateWithDuration(FadeDuration, animations: {
            self.alpha = 0
            }, completion: { (complate) in
                self.shown = false
                self.imageView?.stopAnimating()
                complated ()
        })
    }
    
    func overlay () -> UIView {
        if (overlayView == nil) {
            overlayView = UIView (frame: Window.frame)
            overlayView?.backgroundColor = UIColor.blackColor()
            overlayView?.alpha = 0
            
            UIView.animateWithDuration(0.3, animations: { () -> Void in
                self.overlayView!.alpha = self.OverlayAlpha
            })
        }
        
        return overlayView!
    }
    
    
    
    // MARK: Gif
    
    class func setGif (name: String) {
        self.instance.imageView?.stopAnimating()
        
    }
    
    class func setGif (bundle: NSBundle) {
        self.instance.imageView?.stopAnimating()
        
    }
    
    class func SetGif (images: Array<UIImage>) {
        self.instance.imageView?.stopAnimating()
        self.instance.imageView?.animationImages = images
        self.instance.imageView?.startAnimating()
    }
}
