//
//  WeatherHomeViewController.swift
//  OpenWeather
//
//  Created by Willy Hsu on 2025/6/27.
//

import Foundation
import UIKit
import SnapKit

class WeatherHomeViewController: UIViewController {
    
    private let logolabel: UILabel = {
        let label = UILabel()
        label.text = "OpenWeather"
        label.textColor = .label
        label.font = .systemFont(ofSize: 36, weight: .bold)
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(logolabel)
        logolabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
}
