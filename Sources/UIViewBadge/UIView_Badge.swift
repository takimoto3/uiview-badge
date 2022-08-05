//
//  UIView_Badge.swift
//
//  Created by Masato Takimoto on 2021/06/07.
//

import UIKit

public enum BadgeAlignment {
    case topLeading(x: CGFloat, y: CGFloat)
    case topTrailing(x: CGFloat, y: CGFloat)
    case bottomLeading(x: CGFloat, y: CGFloat)
    case bottomTrailing(x: CGFloat, y: CGFloat)

    func pointOf(view: UIView, size: CGSize) -> CGPoint {
        switch self {
        case let .topLeading(x, y):
            let radius = (-size.height / 2)
            return .init(x: 0 + x + radius, y: 0 + y + radius)
        case let .topTrailing(x, y):
            return .init(x: (view.frame.width - size.width) + x + (size.height / 2), y: y + (-size.height / 2))
        case let .bottomLeading(x, y):
            return .init(x: x + (-size.height / 2), y: (view.frame.height - size.height) + y + (size.height / 2))
        case let .bottomTrailing(x, y):
            return .init(x: (view.frame.width - size.width) + x + (size.height / 2), y: (view.frame.height - size.height) + y + (size.height / 2))
        }
    }
}

final class BadgeContent: NSObject {
    var isBarButtonItem: Bool = false
    var circle: UIView!
    var label: UILabel?
    var labelFont: UIFont = .systemFont(ofSize: 13)
    var height: CGFloat?
    var maxWidth: CGFloat?
    var dotHeight: CGFloat?
    var alignment: BadgeAlignment = .topLeading(x:0, y:0)
    var paddingWidth: CGFloat = 13.5
    var landscapeScale: CGFloat = 0.75
    var positionX: CGFloat = .zero
    var positionY: CGFloat = .zero
    var appearAnimation: BadgeAppearAnimation?
    var disappearAnimation: BadgeDisappearAnimation?
}


//MARKS: - Extensions

fileprivate var badgeObjectKey: UInt8 = 0

extension UIView {
    private(set) var badgeContent: BadgeContent? {
        get {
            return objc_getAssociatedObject(self, &badgeObjectKey) as? BadgeContent
        }
        set {
            objc_setAssociatedObject(self, &badgeObjectKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    public func setupBadge(_ config: BadgeConfiguration = .default, isBarButtonItem: Bool = false) {
        if self.badgeContent != nil {
            return
        }
        let badge = BadgeContent()
        badge.isBarButtonItem = isBarButtonItem
        let circle = UIView()
        circle.layer.borderColor = config.borderColor.cgColor
        circle.layer.borderWidth = config.borderWidth
        circle.backgroundColor = config.circleColor
        circle.alpha = config.opacity
        if config.enableShadow {
            circle.layer.shadowOffset = CGSize(width: 1.0, height: 1.0)
            circle.layer.shadowRadius = 1.0
            circle.layer.shadowOpacity = 0.5
            circle.layer.shadowColor = UIColor.black.cgColor
        }
        badge.circle = circle
        switch config.badgeType {
        case .normal:
            let label = UILabel(frame: circle.frame)
            label.isUserInteractionEnabled = false
            label.font = config.font
            label.textAlignment = config.textAlignment
            label.textColor = config.textColor
            label.backgroundColor = .clear
            badge.label = label
            badge.height = config.badgeHeight
        case .dot:
            badge.dotHeight = config.dotHeight
        }
        badge.maxWidth = config.maxWidth
        badge.alignment = config.badgeAlignment
        badge.appearAnimation = config.appearAnimation
        badge.disappearAnimation = config.disappearAnimation

        self.addSubview(badge.circle)
        if let label = badge.label {
            self.addSubview(label)
            self.bringSubviewToFront(label)
        }
        self.badgeContent = badge
    }

    fileprivate func unloadBadge() {
        NotificationCenter.default.removeObserver(self)
        objc_setAssociatedObject(self, &badgeObjectKey, nil, .OBJC_ASSOCIATION_ASSIGN)
    }

    @objc fileprivate func updateBadgeView() {
        guard let content = badgeContent else {
            return
        }
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first as? UIWindowScene
        let window = windowScene?.windows.first
        let orientation = window?.windowScene?.interfaceOrientation ?? .unknown
        var scale: CGFloat = 1.0
        var width: CGFloat = 0.0
        var height: CGFloat = 0.0
        if content.isBarButtonItem && orientation.isLandscape {
            scale = content.landscapeScale
            content.label?.font = content.labelFont.withSize(content.labelFont.pointSize * scale)
        } else {
            content.label?.font = content.labelFont
        }

        if let dotHeight = content.dotHeight {
            width = dotHeight * scale
            height = dotHeight * scale
        } else {
            content.label!.sizeToFit()
            height = content.height! * scale
            width = max(height, ((content.label!.frame.size.width * scale) + content.paddingWidth))
            if let maxWidth = content.maxWidth {
                width = width > maxWidth ? maxWidth + content.paddingWidth : width
            }
        }
        let point = content.alignment.pointOf(view: self, size: CGSize(width: width, height: height))
        content.circle.frame = CGRect(x: point.x, y: point.y, width: width, height: height)
        content.label?.frame = content.circle.frame
        content.circle.layer.cornerRadius = height / 2
    }

    public func showBadge(_ value: String = "", animated flag: Bool = true) {
        guard let badge = self.badgeContent else {
            return
        }
        if value != "" {
            badge.label?.text = value
        }
        updateBadgeView()

        if flag, let animation = badge.appearAnimation {
            animation.animate(circle: badge.circle, label: badge.label)
        }
        badge.circle.isHidden = false
        badge.label?.isHidden = false
    }

    public func hideBadge(animated flag: Bool = true) {
        guard let badge = badgeContent else {
            return
        }
        if flag, let animation = badge.disappearAnimation {
            animation.animate(circle: badge.circle, label: badge.label)
            return
        }
        badge.circle.isHidden = true
        badge.label?.isHidden = true
    }

    public func isBadgeHideen() -> Bool {
        guard let badge = badgeContent else {
            return false
        }
        return badge.circle.isHidden
    }
}

extension UIBarButtonItem {
    private(set) var tmpConfig: BadgeConfiguration? {
        get {
            return objc_getAssociatedObject(self, &badgeObjectKey) as? BadgeConfiguration
        }
        set {
            objc_setAssociatedObject(self, &badgeObjectKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    public func setupBadge(_ config: BadgeConfiguration = .default) {
        self.tmpConfig = config
    }

    private func valueForView() -> UIView? {
        if let view = self.value(forKey: "view") as? UIView {
            return view
        } else if let view = self.customView {
            return view
        }
        return nil
    }

    public func showBadge(_ value: String = "", animated flag: Bool = true) {
        guard let view = valueForView() else {
            return
        }
        if view.badgeContent == nil, let config = self.tmpConfig {
            NotificationCenter.default.addObserver(view, selector: #selector(view.updateBadgeView), name: UIDevice.orientationDidChangeNotification, object: nil)
            view.setupBadge(config, isBarButtonItem: true)
            objc_removeAssociatedObjects(config)
        }
        guard let badge = view.badgeContent else {
            return
        }
        if value != "" {
            badge.label?.text = value
        }
        view.updateBadgeView()

        if flag, let animation = badge.appearAnimation {
            animation.animate(circle: badge.circle, label: badge.label)
        }
        badge.circle.isHidden = false
        badge.label?.isHidden = false
    }

    public func hideBadge(animated flag: Bool = true) {
        guard let view = valueForView() else {
            return
        }
        view.hideBadge(animated: flag)
    }

    public func isBadgeHideen() -> Bool {
        guard let view = valueForView() else {
            return false
        }
        return view.isBadgeHideen()
    }
}


// MARKS: - Configuration

public struct BadgeConfiguration {
    public enum BadgeType {
        case normal
        case dot
    }

    public static var `default`: BadgeConfiguration {
        return .init()
    }

    public var badgeType: BadgeType
    public var badgeAlignment: BadgeAlignment
    public var borderColor: UIColor
    public var borderWidth: CGFloat
    public var circleColor: UIColor
    public var dotHeight: CGFloat
    public var badgeHeight: CGFloat?
    public var font: UIFont
    public var textColor: UIColor
    public var textAlignment: NSTextAlignment
    public var maxWidth: CGFloat?
    public var appearAnimation: BadgeAppearAnimation?
    public var disappearAnimation: BadgeDisappearAnimation?
    public var enableShadow: Bool
    public var opacity: CGFloat
    public var scaleForLandscape: CGFloat

    public init(type: BadgeType = .normal,
                alignment: BadgeAlignment = .topTrailing(x: 0, y: 0),
                borderColor: UIColor = .clear,
                boderWidth: CGFloat = 0.0,
                circleColor: UIColor = .systemRed,
                dotHeight: CGFloat = 9.0,
                badgeHeight: CGFloat? = 21.0,
                font: UIFont = .systemFont(ofSize: 13),
                textColor: UIColor = .white,
                textAlignment: NSTextAlignment = .center,
                maxWidth: CGFloat? = nil,
                appearAnimation: BadgeAppearAnimation? = SimpleAppearAnimation(),
                disappearAnimation: BadgeDisappearAnimation? = SimpleDisappearAnimation(),
                enableShadow: Bool = false,
                opacity: CGFloat = 1.0,
                scaleForLandscape: CGFloat = 0.75) {
        self.badgeType = type
        self.badgeAlignment = alignment
        self.dotHeight = dotHeight
        self.badgeHeight = badgeHeight
        self.circleColor = circleColor
        self.textColor = textColor
        self.font = font
        self.textAlignment = textAlignment
        self.borderColor = borderColor
        self.borderWidth = boderWidth
        self.maxWidth = maxWidth
        self.appearAnimation = appearAnimation
        self.disappearAnimation = disappearAnimation
        self.enableShadow = enableShadow
        self.opacity = opacity
        self.scaleForLandscape = scaleForLandscape
    }
}
