//
//  SendCommandViewController.swift
//  Data Viewer
//
//  Created by Mikk Rätsep on 25/05/2018.
//  Copyright © 2018 High-Mobility OÜ. All rights reserved.
//

import AutoAPI
import UIKit


class SendCommandViewController: UIViewController {

    @IBOutlet var bytesTextField: UITextField!
    @IBOutlet var otherTextField: UITextField!  // TODO: Delete
    @IBOutlet var hexKeyboardView: HexKeyboardView!
    @IBOutlet var sendButton: UIButton!


    // MARK: IBActions

    @IBAction func backgroundTapGestureRecognised(_ sender: UITapGestureRecognizer) {
        bytesTextField.resignFirstResponder()
        otherTextField.resignFirstResponder()
    }

    @IBAction func sendButtonTapped(_ sender: UIButton) {
        // TODO: This
    }


    // MARK: UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        hexKeyboardView.bounds.size.height = view.bounds.height * 0.5
        hexKeyboardView.bounds.size.width = view.bounds.width
        hexKeyboardView.textfield = otherTextField

        otherTextField.inputView = hexKeyboardView
    }
}
