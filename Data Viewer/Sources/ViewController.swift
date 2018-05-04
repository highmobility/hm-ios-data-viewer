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
        if connectionMethodSegment.selectedSegmentIndex == 0 {
            enableInteractions(false)
            startBluetoothBroadcasting()
        }
        else {
            sendInitialCommand(usingBluetooth: false)
        }
    }


    // MARK: UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        displayText("Initialising device and downloading Access Certificates")
        enableInteractions(false)
        initaliseTheDevice()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        disconnectBluetooth()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let tableViewController = segue.destination as? TableViewController,
            let debugTree = sender as? DebugTree else {
                return
        }

        tableViewController.receivedDebugTree(debugTree)
    }
}

extension ViewController: TheDeviceDelegate {

    func theDevice(commandReceived bytes: [UInt8]) {
        guard let command = AutoAPI.parseBinary(bytes) else {
            return displayText("Failed to parse AutoAPI command")
        }

        OperationQueue.main.addOperation {
            self.performSegue(withIdentifier: "showTableViewController", sender: command.debugTree)
        }
    }

    func theDevice(changed to: Result<ConnectionState>) {
        switch to {
        case .failure(let text):
            displayText(text)

        case .success(let state):
            switch state {
            case .initialised:
                displayText("Ready to use")
                enableInteractions(true)

            case .disconnected:
                displayText("Disconnected")
                enableInteractions(true)

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

    func displayText(_ text: String) {
        OperationQueue.main.addOperation {
            self.errorLabel.text = text
        }
    }

    func enableInteractions(_ enable: Bool) {
        OperationQueue.main.addOperation {
            self.connectButton.isEnabled = enable
            self.connectionMethodSegment.isEnabled = enable
        }
    }

    func sendInitialCommand(usingBluetooth: Bool) {
        let command = VehicleStatus.getVehicleStatus

        sendCommand(command, usingBluetooth: usingBluetooth)
    }
}
