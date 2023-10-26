//
//  ViewController.swift
//  LocationDemo
//
//  Created by Denis Selivanov on 10/23/23.
//

import UIKit
import MapKit

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func letsGoButtonAction(_ sender: Any) {
        let vc = UIKitLocationController(nibName: String(describing: UIKitLocationController.self), bundle: nil)
        self.navigationController?.pushViewController(vc, animated: true)
    }
}
