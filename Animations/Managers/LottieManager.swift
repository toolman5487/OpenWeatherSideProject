//
//  LottieManager.swift
//  OpenWeather
//
//  Created by Willy Hsu on 2025/6/29.
//

import Lottie
import UIKit
import SnapKit

final class LottieManager {
    static func makeLoadingView(named name: String) -> LottieAnimationView {
        let animation = LottieAnimation.named(name)
        let view = LottieAnimationView(animation: animation)
        view.loopMode = .loop
        view.contentMode = .scaleAspectFit
        view.backgroundBehavior = .pauseAndRestore
        
        view.snp.makeConstraints { make in
            make.width.height.equalTo(120)
        }
        
        return view
    }
}
