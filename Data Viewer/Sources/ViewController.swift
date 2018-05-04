//
//  ViewController.swift
//  Data Viewer
//
//  Created by Mikk Rätsep on 02/05/2018.
//  Copyright © 2018 High-Mobility OÜ. All rights reserved.
//

import AutoAPI
import UIKit


class ViewController: UIViewController {

    @IBOutlet var connectButton: UIButton!
    @IBOutlet var connectionMethodSegment: UISegmentedControl!
    @IBOutlet var errorLabel: UILabel!


    // MARK: IBActions

    @IBAction func connectButtonTapped(_ sender: UIButton) {
        if isBluetoothSelected {
            enableInteractions(false)
            
            do {
                try masterController?.startBluetoothBroadcasting()
            }
            catch {
                displayText("Failed to start Bluetooth broadcasting: \(error)")
            }
        }
        else {
            masterController?.refreshVehicleStatus(usingBluetooth: false)
        }
    }


    // MARK: Methods

    func refreshVehicleStatus() {
        masterController?.refreshVehicleStatus(usingBluetooth: isBluetoothSelected)
    }


    // MARK: UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        displayText("Initialising device and downloading Access Certificates")
        enableInteractions(false)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        masterController?.disconnectBluetooth()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Send the (tableview-) controller the latest "data"
        guard let deviceUpdatable = segue.destination as? DeviceUpdatable,
            let debugTree = sender as? AutoAPI.DebugTree else {
                return
        }

        deviceUpdatable.deviceReceived(debugTree: debugTree)
    }
}

extension ViewController: DeviceUpdatable {

    func deviceChanged(to result: Result<ConnectionState>) {
        switch result {
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
                popToRootViewController()

            case .broadcasting(let name):
                displayText("Broadcasting... \(name)")

            case .connected:
                displayText("Connected...")

            case .authenticated:
                displayText("Authenticated, sending command...")
                masterController?.refreshVehicleStatus(usingBluetooth: true)
            }
        }
    }

    func deviceReceived(debugTree: AutoAPI.DebugTree) {
        // Push the 1st TableViewController if none present
        guard let count = navigationController?.viewControllers.count, count == 1 else {
            return
        }

        performSegue(withIdentifier: "showTableViewController", sender: debugTree)
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

    func enableInteractions(_ enable: Bool) {
        OperationQueue.main.addOperation {
            self.connectButton.isEnabled = enable
            self.connectionMethodSegment.isEnabled = enable
        }
    }

    func popToRootViewController() {
        OperationQueue.main.addOperation {
            guard let viewControllers = self.navigationController?.viewControllers, viewControllers.count > 1 else {
                return
            }

            self.navigationController?.popToRootViewController(animated: true)
        }
    }
}
