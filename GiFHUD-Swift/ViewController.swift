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
    GIFHUD.shared.setGif(named: "pika.gif")
  }

  @IBAction func showPressed(_ sender: AnyObject) {
    GIFHUD.shared.show()
  }

  @IBAction func showWithOverlayPressed(_ sender: AnyObject) {
    GIFHUD.shared.show(withOverlay: true, duration: 2)
  }

  @IBAction func dismissPressed(_ sender: AnyObject) {
    GIFHUD.shared.dismiss(completion: {
      print("GiFHUD dismissed")
    })
  }
}
