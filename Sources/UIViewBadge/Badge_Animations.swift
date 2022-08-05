//
//  Badge_Animations.swift
//
//
//  Created by Masato Takimoto on 2021/06/16.
//

import UIKit

public protocol BadgeAppearAnimation {
    func animate(circle: UIView, label: UILabel?)
}

public protocol BadgeDisappearAnimation {
    func animate(circle: UIView, label: UILabel?)
}

public struct SimpleAppearAnimation: BadgeAppearAnimation {
    public init() {}

    public func animate(circle: UIView, label: UILabel?) {
        circle.transform = CGAffineTransform(scaleX: 0.0, y: 0.0)
        label?.transform = CGAffineTransform(scaleX: 0.0, y: 0.0)
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseIn, animations: {
            circle.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            label?.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            circle.isHidden = false
            label?.isHidden = false
        }, completion: { _ in
            circle.transform = .identity
            label?.transform = .identity
        })
    }
}

public class SimpleDisappearAnimation: BadgeDisappearAnimation {

    public init() {}

    public func animate(circle: UIView, label: UILabel?) {
        circle.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
        label?.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseIn, animations: {
            circle.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
            label?.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        }, completion: { _ in
            circle.isHidden = true
            label?.isHidden = true
            circle.transform = .identity
            label?.transform = .identity
        })
    }
}


public let pop = PopAppearAnimation()

public class PopAppearAnimation: BadgeAppearAnimation {
    public init() {}

    public func animate(circle: UIView, label: UILabel?) {
        label?.transform = CGAffineTransform(scaleX: 0.0, y: 0.0)
        circle.transform = CGAffineTransform(scaleX: 0.0, y: 0.0)
        UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.0, options: .curveEaseOut, animations: {
                    circle.transform = .identity
                    label?.transform = .identity
                }, completion: nil)
    }
}

