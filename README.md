GiFHUD-Swift
============

progress hud with ability to display gif images implemented with swift

Demo
----

![alt tag](https://raw.githubusercontent.com/cemolcay/GiFHUD/master/demo.gif)

Install
----

``` ruby
pod 'GiFHUD-Swift'
```

Usage
-----

- import GIFHUD  
- Add your gif file or image sequance files to your project.  

``` swift
// Setup gif image
GIFHUD.shared.setGif("pika.gif")
GIFHUD.shared.show()
```

Thats it!

Just use `GIFHUD.shared.show(with overlay:duration:)` for showing the hud.  
`GIFHUD.shared.dismiss()` for dismissing the hud.  

``` swift
public func setGif(named: String)
public func setGif(bundle: NSBundle)
public func SetGif(images: [UIImage])
```

You can set your gif with giving its `String` name, `Bundle` url or `Array` of `UIImage`s.

Optional values
---------------

``` swift
var size            : CGFloat           = 150
var fadeDuration    : TimeInterval      = 0.3
var gifSpeed        : CGFloat           = 0.3
var overlayAlpha    : CGFloat           = 0.3
```

If you want to customise the looking just edit these values

Credits
=======

The animated gif to UIImage swift library i used: <br>
https://github.com/kaishin/gifu


