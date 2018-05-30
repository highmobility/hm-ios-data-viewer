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
        let settings = HonkHornFlashFlights.Settings(honkHornSeconds: 3, flashLightsTimes: nil)

        textfield?.text = HonkHornFlashFlights.honkHornFlashLights(settings).hex
    }

    @IBAction func lockDoorsTapped(_ sender: UIButton) {
        textfield?.text = DoorLocks.lockUnlock(.lock).hex
    }

    @IBAction func unlockDoorsTapped(_ sender: UIButton) {
        textfield?.text = DoorLocks.lockUnlock(.unlock).hex
    }
}
