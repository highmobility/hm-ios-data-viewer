//
//  HexKeyboardView.swift
//  Data Viewer
//
//  Created by Mikk Rätsep on 25/05/2018.
//  Copyright © 2018 High-Mobility OÜ. All rights reserved.
//

import UIKit


class HexKeyboardView: UIView {

    weak var textfield: UITextField?


    // MARK: IBOutlets

    @IBOutlet var standardButtons: [UIButton]!


    // MARK: IBActions

    @IBAction func buttonTapped(_ sender: UIButton) {
        let text = textfield?.text ?? ""

        if let value = sender.titleLabel?.text {
            textfield?.text = text + value
        }
        else {
            textfield?.text = String(text.dropLast())
        }
    }
}
