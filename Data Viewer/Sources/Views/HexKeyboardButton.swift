//
//  HexKeyboardButton.swift
//  Reference App
//
//  Created by Mikk Rätsep on 07/11/2016.
//  Copyright © 2016 High-Mobility GmbH. All rights reserved.
//

import UIKit


@IBDesignable class HexKeyboardButton: UIButton {

    // MARK: UIView

    override func layoutSubviews() {
        super.layoutSubviews()

        layer.cornerRadius = 4.0
    }


    // MARK: Init

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        layer.cornerRadius = 4.0
        layer.shadowColor = UIColor.darkGray.cgColor
        layer.shadowOpacity = 1.0
        layer.shadowRadius = 1.0
        layer.shadowOffset = CGSize(width: 0.0, height: 1.0)

        setBackgroundImage(UIColor.lightGray.image, for: .highlighted)
    }
}


private extension UIColor {

    var image: UIImage? {
        let rect = CGRect(origin: .zero, size: CGSize(width: 1.0, height: 1.0))

        UIGraphicsBeginImageContext(rect.size)

        setFill()

        UIRectFill(rect)

        let image = UIGraphicsGetImageFromCurrentImageContext()

        UIGraphicsEndImageContext()

        return image
    }
}
