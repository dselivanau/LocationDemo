//
//  ViewController.swift
//  LocationDemo
//
//  Created by Denis Selivanov on 10/23/23.
//

import UIKit
import MapKit

struct TripModel: Codable {
    let agreementId: String
    let expireDate: Date
}

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func letsGoButtonAction(_ sender: Any) {
        let vc = UIKitLocationController(nibName: String(describing: UIKitLocationController.self), bundle: nil)
        self.navigationController?.pushViewController(vc, animated: true)
    }
}
