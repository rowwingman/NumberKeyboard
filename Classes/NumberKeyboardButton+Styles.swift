//
//  NumberKeyboardButton+Styles.swift
//  NumberKeyboardExample
//
//  Created by Maksym Prokopchuk on 26/2/17.
//  Copyright © 2017 Maksym Prokopchuk. All rights reserved.
//

import Foundation
import UIKit

extension NumberKeyboardButton {

    convenience init(numberKey title: String, font: UIFont, target: Any?, action: Selector) {
        self.init(style: .white)
        self.setTitle(title, for: .normal)
        self.titleLabel?.font = font
        self.addTarget(target, action: action, for: .touchUpInside)
    }

    convenience init(doneKeyTitle title: String, font: UIFont, target: Any?, action: Selector) {
        self.init(style: .done)
        self.setTitle(title, for: .normal)
        self.titleLabel?.font = font
        self.addTarget(target, action: action, for: .touchUpInside)
    }

    convenience init(backspaceImage: UIImage?, target: Any?, action: Selector) {
        self.init(style: .gray)
        self.addTarget(target, action: action, for: .touchUpInside)
        self.setImage(backspaceImage, for: .normal)
    }

    convenience init(decimalPoint point: String, font: UIFont, target: Any?, action: Selector) {
        self.init(style: .white)
        self.setTitle(point, for: .normal)
        self.titleLabel?.font = font
        self.addTarget(target, action: action, for: .touchUpInside)
    }

//    let specialButton = NumberKeyboardButton(style: .gray)
//    specialButton.addTarget(self, action: #selector(p_tapSpecialKey(button:)), for: .touchUpInside)
//    buttons[NumberKeyboardButtonType.special.rawValue] = specialButton

}
