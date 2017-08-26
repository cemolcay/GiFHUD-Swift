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

    @IBAction func showPressed(_ sender: AnyObject) {
        GiFHUD.show()
    }

    @IBAction func showWithOverlayPressed(_ sender: AnyObject) {
        GiFHUD.showWithOverlay()

        let delay = DispatchTime.now() + Double(Int64(2 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: delay, execute: {
            GiFHUD.dismiss()
        })
    }
    
    @IBAction func dismissPressed(_ sender: AnyObject) {
        GiFHUD.dismiss()
    }
}

