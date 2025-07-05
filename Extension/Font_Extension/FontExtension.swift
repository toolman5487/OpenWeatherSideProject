//
//  FontExtension.swift
//  OpenWeather
//
//  Created by Willy Hsu on 2025/7/5.
//

import Foundation
import UIKit

extension UIFont {
    static func regular(size: CGFloat) -> UIFont {
        return .systemFont(ofSize: size, weight: .regular)
    }
    static func semibold(size: CGFloat) -> UIFont {
        return .systemFont(ofSize: size, weight: .semibold)
    }
    static func bold(size: CGFloat) -> UIFont {
        return .systemFont(ofSize: size, weight: .bold)
    }
}
