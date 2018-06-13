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

// MARK: - UIImage Extension

public typealias _ImageLiteralType = UIImage
public extension UIImage {
  private convenience init!(failableImageLiteral name: String) {
    self.init(named: name)
  }

  public convenience init(imageLiteralResourceName name: String) {
    self.init(failableImageLiteral: name)
  }
}

// MARK: - UIImageView Extension

public class GIFHUDImageView: UIImageView {

  // MARK: Computed Properties

  public var animatableImage: GIFHUDImage? {
    if image is GIFHUDImage {
      return image as? GIFHUDImage
    } else {
      return nil
    }
  }

  public var isAnimatingGif: Bool {
    return animatableImage?.isAnimating ?? false
  }

  public var animatable: Bool {
    return animatableImage != nil
  }

  // MARK: Overrides
  public override func display(_ layer: CALayer) {
    if let image = animatableImage {
      if let frame = image.currentFrame {
        layer.contents = frame.cgImage
      }
    }
  }

  // MARK: Setter Methods

  public func setAnimatableImage(named name: String) {
    image = GIFHUDImage(image: name, delegate: self)
    layer.setNeedsDisplay()
  }

  public func setAnimatableImage(data: Data) {
    image = GIFHUDImage(data: data, delegate: self)
    layer.setNeedsDisplay()
  }

  // MARK: Animation

  public func startAnimatingGif() {
    if animatable {
      animatableImage?.resumeAnimation()
    }
  }

  public func stopAnimatingGif() {
    if animatable {
      animatableImage?.pauseAnimation()
    }
  }
}

// MARK: - UIImage Extension

public class GIFHUDImage: UIImage {

  public func CGImageSourceContainsAnimatedGIF(_ imageSource: CGImageSource) -> Bool {
    let isTypeGIF = UTTypeConformsTo(CGImageSourceGetType(imageSource)!, kUTTypeGIF)
    let imageCount = CGImageSourceGetCount(imageSource)
    return isTypeGIF != false && imageCount > 1
  }

  public func CGImageSourceGIFFrameDuration(_ imageSource: CGImageSource, index: Int) -> TimeInterval {
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

  public let framesToPreload = 10
  public let maxTimeStep = 1.0

  // MARK: Public Properties

  public var delegate: GIFHUDImageView?
  public var frameDurations = [TimeInterval]()
  public var frames = [UIImage?]()
  public var totalDuration: TimeInterval = 0.0

  // MARK: Private Properties

  private lazy var displayLink: CADisplayLink = CADisplayLink(target: self, selector: #selector(updateCurrentFrame))
  private lazy var preloadFrameQueue: DispatchQueue! = DispatchQueue(label: "GIFHUDPreloadImages", attributes: [])
  private var currentFrameIndex = 0
  private var imageSource: CGImageSource?
  private var timeSinceLastFrameChange: TimeInterval = 0.0

  // MARK: Computed Properties

  public var currentFrame: UIImage? {
    return frameAtIndex(currentFrameIndex)
  }

  public var isAnimated: Bool {
    return imageSource != nil
  }


  // MARK: Initializers

  public required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }

  public init(data: Data, delegate: GIFHUDImageView?) {
    let imageSource = CGImageSourceCreateWithData(data as CFData, nil)
    self.delegate = delegate

    super.init()
    attachDisplayLink()
    prepareFrames(imageSource)
    pauseAnimation()
  }

  public convenience init?(image named: String, delegate: GIFHUDImageView?) {
    guard let data = try? Data(contentsOf: Bundle.main.bundleURL.appendingPathComponent(named))
      else { return nil }
    self.init(data: data, delegate: delegate)
  }

  // MARK: Display Link Helpers

  public func attachDisplayLink() {
    displayLink.add(to: RunLoop.main, forMode: RunLoopMode.commonModes)
  }

  // MARK: Frame Methods

  private func prepareFrames(_ source: CGImageSource!) {
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

  private func frameAtIndex(_ index: Int) -> UIImage? {
    if Int(index) >= self.frames.count { return nil }

    let image: UIImage? = self.frames[Int(index)]
    updatePreloadedFramesAtIndex(index)

    return image
  }

  private func updatePreloadedFramesAtIndex(_ index: Int) {
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

  @objc private func updateCurrentFrame() {
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

  public func pauseAnimation() {
    displayLink.isPaused = true
  }

  public func resumeAnimation() {
    displayLink.isPaused = false
  }

  public var isAnimating: Bool {
    return !displayLink.isPaused
  }
}

// MARK: - GIFHUD

public class GIFHUD: UIView {
  public static let shared = GIFHUD()

  public var hudSize: CGSize = CGSize(width: 180, height: 140)
  public var fadeDuration: TimeInterval = 0.3
  public var gifSpeed: CGFloat = 0.3
  public var overlayAlpha: CGFloat = 0.3

  private(set) public var overlayView: UIView?
  private(set) public var imageView: GIFHUDImageView?
  private(set) public var isShowing: Bool = false

  public override var window: UIWindow? {
    return UIApplication.shared.keyWindow
  }

  // MARK: Init

  private init() {
    super.init(frame: CGRect (x: 0, y: 0, width: hudSize.width, height: hudSize.height))

    alpha = 0
    center = window?.center ?? .zero
    clipsToBounds = false
    layer.backgroundColor = UIColor(white: 0, alpha: 0.5).cgColor
    layer.cornerRadius = 10
    layer.masksToBounds = true

    imageView = GIFHUDImageView(frame: bounds.insetBy(dx: 20, dy: 20))
    addSubview(imageView!)
  }

  public required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }

  // MARK: HUD

  public func show(withOverlay: Bool = false, duration: Double? = nil) {
    dismiss(completion: { [unowned self] in

      // Add overlay if needed.
      if withOverlay {
        self.createOverlayView()
        guard let overlayView = self.overlayView else { return }
        self.window?.addSubview(overlayView)
      }

      // Check if added to window
      if self.superview != self.window {
        self.window?.addSubview(self)
        self.center = self.window?.center ?? .zero
      }

      // Bring it front
      self.window?.bringSubview(toFront: self)

      // Start animation
      if let _ = self.imageView?.animationImages {
        self.imageView?.startAnimating()
      } else {
        self.imageView?.startAnimatingGif()
      }

      // Fade in
      self.fadeIn(completion: {
        self.isShowing = true
      })

      // Dismiss if duration set.
      if let duration = duration {
        let time = DispatchTime.now() + Double(Int64(duration * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: time, execute: {
          self.dismiss()
        })
      }
    })
  }

  public func dismiss(completion: (() -> Void)? = nil) {
    guard isShowing else {
      completion?()
      return
    }

    // Remove overlay if needed
    overlayView?.removeFromSuperview()

    // Fade out
    fadeOut(completion: { [unowned self] in
      // Stop animation
      if let _ = self.imageView?.animationImages {
        self.imageView?.stopAnimating()
      } else {
        self.imageView?.stopAnimatingGif()
      }

      self.isShowing = false
      completion?()
    })
  }

  // MARK: Effects

  private func fadeIn(completion: (() -> Void)? = nil) {
    UIView.animate(
      withDuration: fadeDuration,
      animations: {
        self.alpha = 1
      },
      completion: { _ in
        completion?()
      })
  }

  private func fadeOut(completion: (() -> Void)? = nil) {
    UIView.animate(
      withDuration: fadeDuration,
      animations: {
        self.alpha = 0
      },
      completion: { _ in
        completion?()
      })
  }

  private func createOverlayView() {
    if (overlayView == nil) {
      overlayView = UIView (frame: window?.frame ?? .zero)
      overlayView?.backgroundColor = UIColor.black
      overlayView?.alpha = 0

      UIView.animate(withDuration: 0.3, animations: { () -> Void in
        self.overlayView?.alpha = self.overlayAlpha
      })
    }
  }

  // MARK: Gif

  @discardableResult public func setGif(named: String) -> Bool {
    imageView?.animationImages = nil
    imageView?.stopAnimating()

    if let image = GIFHUDImage(image: named, delegate: imageView) {
      imageView?.image = image
      return true
    }

    return false
  }

  @discardableResult public func setGif(bundle: Bundle) -> Bool {
    imageView?.animationImages = nil
    imageView?.stopAnimating()

    if let resourceURL = bundle.resourceURL,
      let data = try? Data(contentsOf: resourceURL) {
      imageView?.image = GIFHUDImage(data: data, delegate: nil)
      return true
    }

    return false
  }

  public func setGif(images: [UIImage]) {
    imageView?.stopAnimatingGif()
    imageView?.animationImages = images
    imageView?.animationDuration = TimeInterval(gifSpeed)
  }
}
