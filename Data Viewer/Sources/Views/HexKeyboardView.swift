//
//  HexKeyboardView.swift
//  Data Viewer
//
//  Created by Mikk Rätsep on 25/05/2018.
//  Copyright © 2018 High-Mobility OÜ. All rights reserved.
//

import AutoAPI
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

    @IBAction func honkHornTapped(_ sender: UIButton) {
        let command = AAHonkHornFlashLights.honkHorn(seconds: 3, flashLightsXTimes: nil)

        textfield?.text = command?.bytes.hex
    }

    @IBAction func lockDoorsTapped(_ sender: UIButton) {
        textfield?.text = AADoorLocks.lockUnlock(.locked).bytes.hex
    }

    @IBAction func unlockDoorsTapped(_ sender: UIButton) {
        textfield?.text = AADoorLocks.lockUnlock(.unlocked).bytes.hex
    }
}
