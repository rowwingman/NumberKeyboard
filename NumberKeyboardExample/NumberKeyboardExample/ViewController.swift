//
//  ViewController.swift
//  NumberKeyboard
//
//  Created by Maksym Prokopchuk on 9/2/17.
//  Copyright © 2017 Maksym Prokopchuk. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    // MARK: - Properties
    @IBOutlet weak var textField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        let keyboard = NumberKeyboard(frame: CGRect.zero)
//        keyboard.allowsDecimalPoint = true
        keyboard.delegate = self

        self.textField.inputView = keyboard
        keyboard.keyInput = self.textField
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.textField.becomeFirstResponder()
    }

}

extension ViewController : NumberKeyboardDelegate {

    func numberKeyboardShouldReturn(_ numberKeyboard: NumberKeyboard) -> Bool {
        return true
    }

}

