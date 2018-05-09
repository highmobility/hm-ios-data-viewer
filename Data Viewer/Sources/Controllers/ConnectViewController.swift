//
//  ConnectViewController.swift
//  Data Viewer
//
//  Created by Mikk Rätsep on 02/05/2018.
//  Copyright © 2018 High-Mobility OÜ. All rights reserved.
//

import AutoAPI
import UIKit


class ConnectViewController: UIViewController {

    @IBOutlet var connectButton: UIButton!
    @IBOutlet var connectionMethodSegment: UISegmentedControl!


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

        displayText("Initialising...")
        enableInteractions(false)

        #if targetEnvironment(simulator)
            connectionMethodSegment.selectedSegmentIndex = 1
            connectionMethodSegment.isEnabled = false
        #endif

        connectButton.layer.borderColor = view.tintColor.cgColor
        connectButton.layer.borderWidth = 1.0
        connectButton.layer.cornerRadius = 4.0
        connectButton.layer.masksToBounds = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        masterController?.disconnectBluetooth()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        navigationItem.prompt = nil
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        navigationItem.backBarButtonItem?.title = (segue.destination is CommandsViewController) ? "Back" : "Disconnect"

        // Send the (tableview-) controller the latest "data"
        guard let deviceUpdatable = segue.destination as? DeviceUpdatable,
            let debugTree = sender as? AutoAPI.DebugTree else {
                return
        }

        deviceUpdatable.deviceReceived(debugTree: debugTree)
    }
}

extension ConnectViewController: DeviceUpdatable {

    func deviceChanged(to result: Result<ConnectionState>) {
        switch result {
        case .failure(let text):
            displayText(text)

        case .success(let state):
            switch state {
            case .initialised:
                displayText(nil)
                enableInteractions(true)

            case .disconnected:
                enableInteractions(true)
                popToRootViewController()

            case .broadcasting(let name):
                displayText("Broadcasting... \(name)")

            case .connected:
                displayText("Connecting...")

            case .authenticated:
                displayText("Authenticated, getting VS...")
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

private extension ConnectViewController {

    var isBluetoothSelected: Bool {
        return connectionMethodSegment.selectedSegmentIndex == 0
    }


    // MARK: Methods

    func displayText(_ text: String?) {
        OperationQueue.main.addOperation {
            self.navigationItem.prompt = text
        }
    }

    func enableInteractions(_ enable: Bool) {
        OperationQueue.main.addOperation {
            self.connectButton.isEnabled = enable

            #if !targetEnvironment(simulator)
                self.connectionMethodSegment.isEnabled = enable
            #endif
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
