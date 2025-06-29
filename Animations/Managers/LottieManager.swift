//
//  LottieManager.swift
//  OpenWeather
//
//  Created by Willy Hsu on 2025/6/29.
//

import Lottie
import UIKit

final class LottieManager {
    static func makeLoadingView(named name: String) -> LottieAnimationView {
        let animation = LottieAnimation.named(name)
        let view = LottieAnimationView(animation: animation)
        view.loopMode = .loop
        view.contentMode = .scaleAspectFit
        view.backgroundBehavior = .pauseAndRestore
        view.translatesAutoresizingMaskIntoConstraints = false
        view.widthAnchor.constraint(equalToConstant: 120).isActive = true
        view.heightAnchor.constraint(equalToConstant: 120).isActive = true
        return view
    }
}
