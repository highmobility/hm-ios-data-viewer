//
//  ViewController.swift
//  Data Viewer
//
//  Created by Mikk Rätsep on 02/05/2018.
//  Copyright © 2018 High-Mobility OÜ. All rights reserved.
//

import AutoAPI
import UIKit


class ViewController: UIViewController, TheDeviceInitialiser, TheDeviceManager {

    // MARK: TheDeviceInitialiser

    var vehicleSerial: Data? = nil


    // MARK: IBOutlets

    @IBOutlet var connectButton: UIButton!
    @IBOutlet var connectionMethodSegment: UISegmentedControl!
    @IBOutlet var errorLabel: UILabel!


    // MARK: IBActions

    @IBAction func connectButtonTapped(_ sender: UIButton) {
        if isBluetoothSelected {
            startBluetoothBroadcasting()
        }
        else {
            sendInitialCommand(usingBluetooth: false)
        }
    }


    // MARK: UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        connectButton.isEnabled = false
        connectionMethodSegment.isEnabled = false

        displayText("Initialising device and downloading Access Certificates")
        initaliseTheDevice()
    }
}

extension ViewController: TheDeviceDelegate {

    func theDevice(commandReceived bytes: [UInt8]) {
        // TODO: <#code#>
        print("command received:", bytes.hex)
    }

    func theDevice(changed to: Result<ConnectionState>) {
        switch to {
        case .failure(let text):
            displayText(text)

        case .success(let state):
            switch state {
            case .initialised:
                displayText("Ready to use")

                OperationQueue.main.addOperation {
                    self.connectButton.isEnabled = true
                    self.connectionMethodSegment.isEnabled = true
                }

            case .disconnected:
                displayText("Disconnected")

            case .broadcasting(let name):
                displayText("Broadcasting... \(name)")

            case .connected:
                displayText("Connected...")

            case .authenticated:
                displayText("Authenticated, sending command...")

                sendInitialCommand(usingBluetooth: true)
            }
        }
    }
}

private extension ViewController {

    var isBluetoothSelected: Bool {
        return connectionMethodSegment.selectedSegmentIndex == 0
    }


    // MARK: Methods

    func displayText(_ text: String) {
        OperationQueue.main.addOperation {
            self.errorLabel.text = text
        }
    }

    func sendInitialCommand(usingBluetooth: Bool) {
        let command = Capabilities.getCapabilities

        sendCommand(command, usingBluetooth: usingBluetooth)
    }
}
