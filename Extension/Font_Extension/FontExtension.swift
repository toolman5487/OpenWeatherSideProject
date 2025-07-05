//
//  FontExtension.swift
//  OpenWeather
//
//  Created by Willy Hsu on 2025/7/5.
//

import Foundation
import UIKit

extension UIFont {
    
    static func ultraLight(size: CGFloat) -> UIFont {
        return .systemFont(ofSize: size, weight: .ultraLight)
    }
    static func thin(size: CGFloat) -> UIFont {
        return .systemFont(ofSize: size, weight: .thin)
    }
    static func light(size: CGFloat) -> UIFont {
        return .systemFont(ofSize: size, weight: .light)
    }
    static func regular(size: CGFloat) -> UIFont {
        return .systemFont(ofSize: size, weight: .regular)
    }
    static func medium(size: CGFloat) -> UIFont {
        return .systemFont(ofSize: size, weight: .medium)
    }
    static func semibold(size: CGFloat) -> UIFont {
        return .systemFont(ofSize: size, weight: .semibold)
    }
    static func bold(size: CGFloat) -> UIFont {
        return .systemFont(ofSize: size, weight: .bold)
    }
    static func heavy(size: CGFloat) -> UIFont {
        return .systemFont(ofSize: size, weight: .heavy)
    }
    static func black(size: CGFloat) -> UIFont {
        return .systemFont(ofSize: size, weight: .black)
    }
}
