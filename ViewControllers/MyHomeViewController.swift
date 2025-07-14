//
//  MyHomeViewController.swift
//  OpenWeather
//
//  Created by Willy Hsu on 2025/7/14.
//

import Foundation
import UIKit

class MyHomeViewController: UIViewController {
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setHomeNavigationBar()
        
    }
    
    func setHomeNavigationBar() {
        self.title = "首頁"
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
    }
    
    
}
