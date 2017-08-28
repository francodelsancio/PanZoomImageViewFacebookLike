//
//  ViewController.swift
//  PanZoomImageViewFacebookLike
//
//  Created by Franco Del Sancio on 16/8/17.
//  Copyright © 2017 Franco Del Sancio. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var imageView: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.layer.cornerRadius = 10
        imageView.layer.masksToBounds = true
        imageView.addZoomGesture()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

