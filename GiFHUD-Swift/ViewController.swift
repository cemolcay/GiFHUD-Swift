//
//  ViewController.swift
//  GiFHUD-Swift
//
//  Created by Cem Olcay on 07/11/14.
//  Copyright (c) 2014 Cem Olcay. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        GiFHUD.setGif("pika.gif")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func showPressed(sender: AnyObject) {
        GiFHUD.show()
    }

    @IBAction func showWithOverlayPressed(sender: AnyObject) {
        GiFHUD.showWithOverlay()

        let delay = dispatch_time(DISPATCH_TIME_NOW, Int64(2 * Double(NSEC_PER_SEC)))
        dispatch_after(delay, dispatch_get_main_queue(), {
            GiFHUD.dismiss()
        })
    }
    
    @IBAction func dismissPressed(sender: AnyObject) {
        GiFHUD.dismiss()
    }
}

