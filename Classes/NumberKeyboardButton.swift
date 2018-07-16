//
//  NumberKeyboardButton.swift
//  NumberKeyboard
//
//  Created by Maksym Prokopchuk on 9/2/17.
//  Copyright © 2017 Maksym Prokopchuk. All rights reserved.
//

import Foundation
import UIKit

/// Specifies the style of a keyboard button.
enum NumberKeyboardButtonStyle {

    /// A white style button, such as those for the number keys.
    case white

    /// A gray style button, such as the backspace key.
    case gray

    /// A done style button, for example, a button that completes some task and returns to the previous view.
    case done

}

enum NumberKeyboardButtonType : Int {
    case numberMin = 0
    case numberMax = 9
    case backspace
    case done
    case special
    case decimalPoint
}


@objc class NumberKeyboardButton : UIButton {

    // MARK: - Dealloc
    deinit {
        self.p_cancelContinousPressIfNeeded()
    }

    // MARK: - Public Properties
    /// The style of the keyboard button.
    private(set) var style : NumberKeyboardButtonStyle = .white

    // MARK: - Private Properties
    private(set) var continuousPressTimer : Timer?

    private(set) var continuousPressTimeInterval : TimeInterval?

    private(set) lazy var fillColor : UIColor = {
        var fillColor : UIColor

        switch self.style {
            case .white:
                fillColor = UIColor.white
            case .gray:
//            if (interfaceIdiom == UIUserInterfaceIdiomPad) {
//                fillColor =  [UIColor colorWithRed:0.674f green:0.7f blue:0.744f alpha:1];
//            } else {
//                fillColor = [UIColor colorWithRed:0.81f green:0.837f blue:0.86f alpha:1];
//            }
                fillColor = UIColor(red: 0.81, green: 0.837, blue: 0.86, alpha: 1.0)
            case .done:
                fillColor = UIColor(red: 0.0, green: 0.479, blue: 1.0, alpha: 1.0)
        }

        return fillColor
    }()

    private(set) lazy var highlightedFillColor : UIColor = {
        var highlightedFillColor : UIColor

        switch self.style {
            case .white:
                highlightedFillColor = UIColor(red: 0.82, green: 0.837, blue: 0.863, alpha: 1.0)
            case .gray:
                highlightedFillColor = UIColor.white
            case .done:
                highlightedFillColor = UIColor.white
        }

        return highlightedFillColor
    }()

    private(set) lazy var controlColor : UIColor = {
        let controlColor : UIColor = self.style == .done ? UIColor.white : UIColor.black
        return controlColor
    }()

    private(set) lazy var highlightedControlColor : UIColor = UIColor.black

    // MARK: - Super Properties
    override var isHighlighted: Bool {
        didSet {
            self.p_configurateAppearance()
        }
    }

    // MARK: - Init
    init(style: NumberKeyboardButtonStyle) {
        self.style = style
        super.init(frame: CGRect.zero)
        self.p_configurateControlTitle(color: self.controlColor, highlightedColor: self.highlightedControlColor)
        self.p_configurateAppearance()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    // MARK: - Configuration
    func p_configurateControlTitle(color: UIColor, highlightedColor: UIColor) {
        self.setTitleColor(color, for: .normal)
        self.setTitleColor(highlightedColor, for: .selected)
        self.setTitleColor(highlightedColor, for: .highlighted)
//        if (interfaceIdiom == UIUserInterfaceIdiomPad) {
//            CALayer *buttonLayer = [self layer];
//            buttonLayer.cornerRadius = 4.0f;
//            buttonLayer.shadowColor = [UIColor colorWithRed:0.533f green:0.541f blue:0.556f alpha:1].CGColor;
//            buttonLayer.shadowOffset = CGSizeMake(0, 1.0f);
//            buttonLayer.shadowOpacity = 1.0f;
//            buttonLayer.shadowRadius = 0.0f;
//        }
    }

    func p_configurateAppearance() {
        if self.isHighlighted || self.isSelected {
            self.backgroundColor = self.highlightedFillColor
            self.imageView?.tintColor = self.controlColor
        }
        else {
            self.backgroundColor = self.fillColor
            self.imageView?.tintColor = self.highlightedControlColor
        }
    }


    // MARK: - States
//    - (void)willMoveToWindow:(UIWindow *)newWindow
//    {
//    [super willMoveToWindow:newWindow];
//
//    if (newWindow) {
//    [self _updateButtonAppearance];
//    }
//    }

    // MARK: -
    // Notes the continuous press time interval, then adds the target/action to the UIControlEventValueChanged event.
    func addTarget(_ target: Any?, action: Selector, forContinuousPress timeInterval: TimeInterval) {
        self.continuousPressTimeInterval = timeInterval;
        self.addTarget(target, action: action, for: .valueChanged)
    }

    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let begins = super.beginTracking(touch, with: event)

        guard let continuousPressTimeInterval = self.continuousPressTimeInterval, continuousPressTimeInterval > 0 else {
            return begins
        }

        if (begins) {
            self.p_beginContinuousPressDelayed()
        }

        return begins
    }

    override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        super.endTracking(touch, with: event)
        self.p_cancelContinousPressIfNeeded()
    }


    // MARK: -
    func p_beginContinuousPress() {
        guard self.isTracking else { return }
        guard let continuousPressTimeInterval = self.continuousPressTimeInterval, continuousPressTimeInterval > 0 else { return }

        self.continuousPressTimer = Timer(timeInterval: continuousPressTimeInterval, target: self, selector: #selector(p_handleContinuousPressTimer(_:)), userInfo: nil, repeats: true)
    }

    @objc func p_handleContinuousPressTimer(_ timer: Timer) {
        guard self.isTracking else {
            self.p_cancelContinousPressIfNeeded()
            return
        }

        self.sendActions(for: .valueChanged)
    }

    func p_beginContinuousPressDelayed() {
//        [self performSelector:@selector(p_beginContinuousPress) withObject:nil afterDelay:self.continuousPressTimeInterval * 2.0f];
    }

    func p_cancelContinousPressIfNeeded() {
//        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(p_beginContinuousPress) object:nil];

        guard let timer = self.continuousPressTimer else { return }
        timer.invalidate()
        self.continuousPressTimer = nil
    }

}
