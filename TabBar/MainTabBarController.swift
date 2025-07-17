//
//  MainTabBarController.swift
//  OpenWeather
//
//  Created by Willy Hsu on 2025/6/27.
//

import Foundation
import UIKit

class MainTabBarController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabBar()
        setupBlurEffect()
    }
    
    private func setupTabBar() {
        let weatherVC = WeatherHomeViewController()
        weatherVC.tabBarItem = UITabBarItem(title: "天氣",
                                            image: UIImage(systemName: "cloud.sun"),
                                            selectedImage: UIImage(systemName: "cloud.sun.fill"))
        let weatherNav = UINavigationController(rootViewController: weatherVC)
        let homeVC = MyHomeViewController()
        homeVC.tabBarItem = UITabBarItem(title: "首頁",
                                            image: UIImage(systemName: "house"),
                                            selectedImage: UIImage(systemName: "house.fill"))
        let homeNav = UINavigationController(rootViewController: homeVC)
       
        viewControllers = [
            weatherNav, homeNav
        ]
    }
    
    private func setupBlurEffect() {
        let blurEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)

        blurEffectView.frame = tabBar.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tabBar.backgroundImage = UIImage()
        tabBar.shadowImage = UIImage()
        tabBar.backgroundColor = UIColor.clear
        tabBar.isTranslucent = true
        
        tabBar.insertSubview(blurEffectView, at: 0)
        tabBar.tintColor = .systemBlue
        tabBar.unselectedItemTintColor = .secondaryLabel
    }
}
