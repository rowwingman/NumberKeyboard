//
//  NumberKeyboard.swift
//  NumberKeyboard
//
//  Created by Maksym Prokopchuk on 9/2/17.
//  Copyright © 2017 Maksym Prokopchuk. All rights reserved.
//

import UIKit

// check only one decimal point
// keyInput how to set when textField is become first responder

/// A simple keyboard to use with numbers and, optionally, a decimal point.
@available(iOS 9.0, *)
@objcMembers class NumberKeyboard: UIInputView, UIInputViewAudioFeedback {

    // MARK: - UIInputViewAudioFeedback
    var enableInputClicksWhenVisible: Bool = true

    // MARK: - Constants
    private let keyboardRows                = 4
    private let keyboardColumns             = 4
    private let rowHeight: CGFloat          = 55.0
    private let keyboardPadBorder: CGFloat  = 7.0
    private let keyboardPadSpacing: CGFloat = 8.0

    // MARK: - Public Properties
    /// The receiver key input object. If nil the object at top of the responder chain is used.
    weak var keyInput: UIKeyInput?

    /// Delegate to change text insertion or return key behavior.
    weak var delegate: NumberKeyboardDelegate?

    private var _allowsDecimalPoint = false {
        didSet {
            // configurate zero number
            self.setNeedsLayout()
        }
    }

    /**
     If true, the decimal separator key will be displayed.
     - note: The default value of this property is **false**.
     */
    var allowsDecimalPoint: Bool {
        get {
            return _allowsDecimalPoint
        }
        set {
            guard _allowsDecimalPoint != newValue else { return }
            _allowsDecimalPoint = newValue
        }
    }

    // UIKitLocalizedString(@"Done");
    private lazy var _returnKeyTitle: String = "Done"

    /**
     The visible title of the Return key.
     - note: The default visible title of the Return key is "**Done**".
     */
    var returnKeyTitle: String {
        get {
            return _returnKeyTitle
        }
        set {
            guard _returnKeyTitle != newValue else { return }
            _returnKeyTitle = newValue

            guard let button = self.buttons[NumberKeyboardButtonType.done.rawValue] else { return }
            button.setTitle(_returnKeyTitle, for: .normal)
        }
    }


    /**
     The button style of the Return key.
     - note: The default value of this property is **NumberKeyboardButtonStyleDone**.
     */
    var returnKeyButtonStyle: NumberKeyboardButtonStyle = .done


    // MARK: - Private Properties
    lazy private(set) var locale = Locale.current

    private lazy var buttons : [Int: UIButton] = {
        let buttonFont = UIFont.systemFont(ofSize: 28.0, weight: UIFont.Weight.light)
        let doneButtonFont = UIFont.systemFont(ofSize: 17.0)

        var buttons = [Int: UIButton]()

        let numberMin = NumberKeyboardButtonType.numberMin.rawValue
        let numberMax = NumberKeyboardButtonType.numberMax.rawValue
        for key in numberMin...numberMax {
            let button = NumberKeyboardButton(numberKey: String(key), font: buttonFont, target: self, action: #selector(p_tapKeyNumber(button:)))
            buttons[key] = button
        }

        let backspaceImage = NumberKeyboard.p_keyboardImageNamed("MMNumberKeyboardDeleteKey")?.withRenderingMode(.alwaysTemplate)

        let backspaceButton = NumberKeyboardButton(backspaceImage: backspaceImage, target: self, action: #selector(p_tapBackspaceKey(button:)))
        backspaceButton.addTarget(self, action: #selector(p_tapBackspaceRepeat(button:)), forContinuousPress: 0.15)
        buttons[NumberKeyboardButtonType.backspace.rawValue] = backspaceButton

        let specialButton = NumberKeyboardButton(style: .gray)
        specialButton.addTarget(self, action: #selector(p_tapSpecialKey(button:)), for: .touchUpInside)
        buttons[NumberKeyboardButtonType.special.rawValue] = specialButton


        let doneButton = NumberKeyboardButton(doneKeyTitle: self.returnKeyTitle, font: doneButtonFont, target: self, action: #selector(p_tapDoneKey(button:)))
        buttons[NumberKeyboardButtonType.done.rawValue] = doneButton

//        NSLocale *locale = self.locale ?: [NSLocale currentLocale];
//        let decimalSeparator = [self.locale objectForKey:NSLocaleDecimalSeparator];
        let decimalPointButton = NumberKeyboardButton(decimalPoint: ".", font: buttonFont, target: self, action: #selector(p_tapDecimalPointKey(button:)))
        buttons[NumberKeyboardButtonType.decimalPoint.rawValue] = decimalPointButton

        for (_, button) in buttons {
            button.isExclusiveTouch = true
            button.addTarget(self, action: #selector(p_playClick(button:)), for: .touchDown)
        }

        return buttons
    }()

    /// Initialize an array for the separators.
    private lazy var separatorViews : [UIView] = {
        var separatorViews = [UIView]()
        var numberOfSeparators = self.keyboardColumns + self.keyboardRows - 1

        for index in 0..<numberOfSeparators {
            let separator = UIView(frame: CGRect.zero)
            separator.backgroundColor = UIColor(white: 0.0, alpha: 0.1)
            separatorViews.append(separator)
        }

        return separatorViews
    }()

    // MARK: - Initializers
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /**
        Initializes and returns a number keyboard view using the specified style information and locale.
     
        An initialized view object or nil if the view could not be initialized.
        - parameters:
            - frame: The frame rectangle for the view, measured in points. The origin of the frame is relative to the superview in which you plan to add it.
            - inputViewStyle: The style to use when altering the appearance of the view and its subviews. For a list of possible values, see **UIInputViewStyle**
            - locale: An **Locale** object that specifies options (specifically the **LocaleDecimalSeparator**) used for the keyboard. Specify nil if you want to use the current locale.

     */
    convenience init(frame: CGRect, inputViewStyle: UIInputViewStyle, locale: Locale) {
        self.init(frame: frame, inputViewStyle: inputViewStyle)
        self.locale = locale
    }

    override init(frame: CGRect, inputViewStyle: UIInputViewStyle) {
        super.init(frame: frame, inputViewStyle: inputViewStyle)
        self.p_initialSetup()
    }

    // MARK: - Accessing keyboard images.
    private class func p_keyboardImageNamed(_ imageName: String) -> UIImage? {
        let imageExtension = "png"

        var image : UIImage?
        let bundle = Bundle(for: NumberKeyboard.self)
        if let imagePath = bundle.path(forResource: imageName, ofType: imageExtension) {
            image = UIImage(contentsOfFile: imagePath)
        }
        else {
            image = UIImage(named: imageName)
        }

        return image
    }

    func p_initialSetup() {

        for (_, button) in self.buttons {
            self.addSubview(button)
        }

        if UI_USER_INTERFACE_IDIOM() == .phone {
            for separatorView in self.separatorViews {
                self.addSubview(separatorView)
            }
        }

        let highlightGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(p_handleHighlight(gestureRecognizer:)))
        self.addGestureRecognizer(highlightGestureRecognizer)

//        // Add default action.
        let dismissImage = NumberKeyboard.p_keyboardImageNamed("MMNumberKeyboardDismissKey")?.withRenderingMode(.alwaysTemplate)
        self.configureSpecialKey(image: dismissImage, target: self, action: #selector(p_dismissKeyboard))

        // Size to fit.
        self.sizeToFit()
    }

    // MARK: -
    /**
        Configures the special key with an image and an action block.
        - parameters:
            - image: The image to display in the key.
            - handler: A handler block.
     */
    func configureSpecialKey(image: UIImage?, actionHandler handler: ()->()) {
//        if (image) {
//            self.specialKeyHandler = handler;
//        } else {
//            self.specialKeyHandler = NULL;
//        }

        guard let button = self.buttons[NumberKeyboardButtonType.special.rawValue] else { return }
        button.setImage(image, for: .normal)
    }

    /**
        Configures the special key with an image and a target-action.
        - parameters:
            - image: The image to display in the key.
            - target: The target object—that is, the object to which the action message is sent.
            - action: A selector identifying an action message.
     */
    func configureSpecialKey(image: UIImage?, target: Any?, action: Selector) {
        guard let button = self.buttons[NumberKeyboardButtonType.special.rawValue] else { return }
        button.setImage(image, for: .normal)

//        __weak typeof(self)weakTarget = target;
//        __weak typeof(self)weakSelf = self;
//
//        [self configureSpecialKeyWithImage:image actionHandler:^{
//            __strong __typeof(&*weakTarget)strongTarget = weakTarget;
//            __strong __typeof(&*weakSelf)strongSelf = weakSelf;
//
//            if (strongTarget) {
//            NSMethodSignature *methodSignature = [strongTarget methodSignatureForSelector:action];
//            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
//            [invocation setSelector:action];
//            if (methodSignature.numberOfArguments > 2) {
//            [invocation setArgument:&strongSelf atIndex:2];
//            }
//            [invocation invokeWithTarget:strongTarget];
//            }
//            }];
    }


    // MARK: - Handle pan gesture
    func p_handleHighlight(gestureRecognizer : UIPanGestureRecognizer) {
        let point = gestureRecognizer.location(in: self)

        guard gestureRecognizer.state == .changed || gestureRecognizer.state == .ended else { return }

        for (_, button) in self.buttons {
            let points = button.frame.contains(point) && !button.isHidden

            if gestureRecognizer.state == .changed {
                button.isHighlighted = points
            }
            else {
                button.isHighlighted = false
            }

            if gestureRecognizer.state == .ended && points {
                button.sendActions(for: .touchUpInside)
            }
        }
    }

    // MARK: - Handle Actions
    func p_playClick(button: NumberKeyboardButton) {
        UIDevice.current.playInputClick()
    }

    func p_tapKeyNumber(button: NumberKeyboardButton) {
        guard self.buttons.values.contains(button) else { return }

        // Get first responder.
        guard let keyInput = self.keyInput else { return }
        guard let title = button.title(for: .normal) else { return }

        // Handle number.
        if let shouldInsert = self.delegate?.numberKeyboard?(self, shouldInsertText: title) {
            guard shouldInsert == true else { return }
        }

        keyInput.insertText(title)
    }

    func p_tapSpecialKey(button: NumberKeyboardButton) {
        guard self.buttons.values.contains(button) else { return }

        // Handle special key.
//        guard let handler = self.spea else { return }

//        dispatch_block_t handler = self.specialKeyHandler;
//        if (handler) {
//            handler();
//        }

    }

    func p_tapDecimalPointKey(button: NumberKeyboardButton) {
        guard self.buttons.values.contains(button) else { return }

        // Get first responder.
        guard let keyInput = self.keyInput else { return }
        guard let decimalText = button.title(for: .normal) else { return }

        // Handle decimal point.
        if let shouldInsert = self.delegate?.numberKeyboard?(self, shouldInsertText: decimalText) {
            guard shouldInsert == true else { return }
        }

        keyInput.insertText(decimalText)
    }

    func p_tapBackspaceKey(button: NumberKeyboardButton) {
        guard self.buttons.values.contains(button) else { return }

        // Get first responder.
        guard let keyInput = self.keyInput else { return }

        // Handle backspace.
        if let shouldDeleteBackward = self.delegate?.numberKeyboardShouldDeleteBackward?(self) {
            guard shouldDeleteBackward == true else { return }
        }

        keyInput.deleteBackward()
    }

    func p_tapDoneKey(button: NumberKeyboardButton) {
        guard self.buttons.values.contains(button) else { return }

        // Handle done.
        if let shouldReturn = self.delegate?.numberKeyboardShouldReturn?(self) {
            guard shouldReturn == true else { return }
        }

        self.p_dismissKeyboard()
    }

    func p_tapBackspaceRepeat(button: NumberKeyboardButton) {
        guard self.buttons.values.contains(button) else { return }

        // Get first responder.
        guard let keyInput = self.keyInput else { return }
        guard keyInput.hasText else { return }

        self.p_playClick(button: button)
        self.p_tapBackspaceKey(button: button)
    }

    // MARK: -
    func p_dismissKeyboard() {
        guard let keyInput = self.keyInput as? UIResponder else { return }
        keyInput.resignFirstResponder()
    }

    // MARK: - Layout
    @inline(__always) func p_(rect: CGRect, contentOrigin: CGPoint, interfaceIdiom: UIUserInterfaceIdiom) -> CGRect {
        var newRect = rect.offsetBy(dx: contentOrigin.x, dy: contentOrigin.y)

        if interfaceIdiom == .pad {
            let inset : CGFloat = self.keyboardPadSpacing / 2.0
            newRect = newRect.insetBy(dx: inset, dy: inset)
        }

        return newRect
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let buttons = self.buttons

        let bounds = self.bounds

        // Settings.
        let interfaceIdiom = UI_USER_INTERFACE_IDIOM()
        let spacing : CGFloat = (interfaceIdiom == .pad) ? self.keyboardPadBorder : 0.0
        let maximumWidth : CGFloat = (interfaceIdiom == .pad) ? 400.0 : bounds.width
        let allowsDecimalPoint = self.allowsDecimalPoint

        let width = min(maximumWidth, bounds.width);
        let contentRect = CGRect(x: round(bounds.width - width) / 2.0,
                                 y: spacing,
                                 width: width,
                                 height: (bounds.height - spacing * 2.0))

        // Layout.
        let columnWidth = contentRect.width / 4.0;
        let rowHeight = self.rowHeight;

        let numberSize = CGSize(width: columnWidth, height: rowHeight)

        // Layout numbers.
        let numberMin = NumberKeyboardButtonType.numberMin.rawValue
        let numberMax = NumberKeyboardButtonType.numberMax.rawValue
        let numbersPerLine = 3

        for key in numberMin...numberMax {
            let button = buttons[key]

            let digit = key - numberMin

            var rect = CGRect(origin: CGPoint.zero, size: numberSize)

            if digit == 0 {
                rect.origin.y = numberSize.height * 3;
                rect.origin.x = numberSize.width;

                if !allowsDecimalPoint {
                    rect.size.width = numberSize.width * 2.0;
//                    button?.contentEdgeInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: numberSize.width)
                }
            }
            else {
                let idx = digit - 1

                let line = idx / numbersPerLine
                let pos = idx % numbersPerLine

                rect.origin.y = CGFloat(line) * numberSize.height
                rect.origin.x = CGFloat(pos) * numberSize.width
            }

            button?.frame = self.p_(rect: rect, contentOrigin: contentRect.origin, interfaceIdiom: interfaceIdiom)
        }

        // Layout special key.

        if let specialKey = buttons[NumberKeyboardButtonType.special.rawValue] {
            var rect = CGRect(origin: CGPoint.zero, size: numberSize)
            rect.origin.y = numberSize.height * 3

            specialKey.frame = self.p_(rect: rect, contentOrigin: contentRect.origin, interfaceIdiom: interfaceIdiom)
        }

        // Layout decimal point.
        if let decimalPointKey = buttons[NumberKeyboardButtonType.decimalPoint.rawValue] {
            var rect = CGRect(origin: CGPoint.zero, size: numberSize)
            rect.origin.x = numberSize.width * 2
            rect.origin.y = numberSize.height * 3

            decimalPointKey.frame = self.p_(rect: rect, contentOrigin: contentRect.origin, interfaceIdiom: interfaceIdiom)
            decimalPointKey.isHidden = !allowsDecimalPoint
        }

        // Layout utility column.
        let utilityButtonKeys = [NumberKeyboardButtonType.backspace.rawValue, NumberKeyboardButtonType.done.rawValue]
        let utilitySize = CGSize(width: columnWidth, height: rowHeight * 2.0);

        for (index, key) in utilityButtonKeys.enumerated() {
            let button = buttons[key]
            var rect = CGRect(origin: CGPoint.zero, size: utilitySize)
            rect.origin.x = columnWidth * 3.0
            rect.origin.y = CGFloat(index) * utilitySize.height
            button?.frame = self.p_(rect: rect, contentOrigin: contentRect.origin, interfaceIdiom: interfaceIdiom)
        }

        // Layout separators if phone.
        if interfaceIdiom == .phone {
            self.p_layoutSeparators(separators: self.separatorViews, contentRect: contentRect, columnWidth: columnWidth)
        }
    }

    func p_layoutSeparators(separators: [UIView], contentRect: CGRect, columnWidth: CGFloat) {
        var scale : CGFloat = 1.0
        if let window = self.window {
            scale = window.screen.scale
        }
        let separatorDimension : CGFloat = 1.0 / scale

        let totalRows = self.keyboardRows

        for (index, separator) in separators.enumerated() {
            var rect = CGRect.zero

            if index < totalRows {
                rect.origin.y = CGFloat(index) * rowHeight

                if index % 2 == 1 {
                    // to not cross backspace and done buttons
                    rect.size.width = contentRect.width - CGFloat(columnWidth)
                }
                else {
                    rect.size.width = contentRect.width
                }

                rect.size.height = separatorDimension
            }
            else {
                let columnIndex = index - totalRows

                rect.origin.x = CGFloat(columnIndex + 1) * columnWidth
                rect.size.width = separatorDimension

                if columnIndex == 1, !self.allowsDecimalPoint {
                    rect.size.height = contentRect.height - rowHeight
                }
                else {
                    rect.size.height = contentRect.height
                }
            }

            separator.frame = self.p_(rect: rect, contentOrigin: contentRect.origin, interfaceIdiom: .phone)
        }
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let interfaceIdiom = UI_USER_INTERFACE_IDIOM();
        let spacing = (interfaceIdiom == .pad) ? self.keyboardPadBorder : 0.0;

        var newSize = size
        newSize.height = self.rowHeight * CGFloat(self.keyboardRows) + spacing * 2.0

        if (newSize.width == 0.0) {
            newSize.width = UIScreen.main.bounds.size.width
        }

        return newSize
    }

//    - (id <UIKeyInput>)keyInput {
//    id <UIKeyInput> keyInput = _keyInput;
//    if (keyInput) {
//    return keyInput;
//    }
//
//    keyInput = [UIResponder MM_currentFirstResponder];
//    if (![keyInput conformsToProtocol:@protocol(UITextInput)]) {
//    NSLog(@"Warning: First responder %@ does not conform to the UIKeyInput protocol.", keyInput);
//    return nil;
//    }
//
//    _keyInput = keyInput;
//
//    return keyInput;
//    }
}
