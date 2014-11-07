GiFHUD-Swift
============

progress hud with ability to display gif images implemented with swift

Demo
----

![alt tag](https://raw.githubusercontent.com/cemolcay/GiFHUD/master/demo.gif)

Usage
-----

Copy & paste the GiFHUD.swift to your project. <br>
Add your gif file or image sequance files to your project. <br>

    //Setup GiFHUD image
    GiFHUD.setGif("pika.gif")
    GiFHUD.show()

Thats it ! <br>

Just use `GiFHUD.show()` or `GiFHUD.showWithOverlay()` for showing the hud. <br>
`GiFHUD.dismiss()` for dismissing the hud.

    class func setGif (name: String)
    class func setGif (bundle: NSBundle)
    class func SetGif (images: Array<UIImage>)

You can set your gif with giving its `String` name, `NSBundle` url or `Array` of `UIImage`s.

Optional values
---------------

    let Size            150
    let FadeDuration    0.3
    let GifSpeed        0.3
    let OverlayAlpha    0.3

If you want to customise the looking just edit these values


Credits
=======

The animated gif to UIImage swift library i used: <br>
https://github.com/kaishin/gifu


