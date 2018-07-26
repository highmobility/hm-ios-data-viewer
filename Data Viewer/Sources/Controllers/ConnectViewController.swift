//
//  ConnectViewController.swift
//  Data Viewer
//
//  Created by Mikk Rätsep on 02/05/2018.
//  Copyright © 2018 High-Mobility OÜ. All rights reserved.
//

import AutoAPI
import HMUtilities
import UIKit


class ConnectViewController: UIViewController {

    @IBOutlet var connectButton: UIButton!
    @IBOutlet var connectionMethodSegment: UISegmentedControl!
    @IBOutlet var linkButton: UIButton!


    // MARK: IBActions

    @IBAction func connectButtonTapped(_ sender: UIButton) {
        if connectionMethodSegment.selectedSegmentIndex == 0 {
            if HighMobilityManager.shared.isBluetoothBroadcasting {
                HighMobilityManager.shared.disconnectBluetooth()

                navigationItem.prompt = nil
                sender.setTitle("CONNECT", for: .normal)
            }
            else {
                enableInteractions(false)

                do {
                    try HighMobilityManager.shared.startBluetoothBroadcasting()
                }
                catch {
                    displayText("Failed to start Bluetooth broadcasting: \(error)")
                    enableInteractions(true)
                }
            }
        }
        else {
            HighMobilityManager.shared.refreshVehicleStatus()
        }
    }

    @IBAction func connectionMethodChanged(_ sender: UISegmentedControl) {
        HighMobilityManager.shared.isBluetoothConnection = sender.selectedSegmentIndex == 0
    }

    @IBAction func linkButtonTapped(_ sender: UIButton) {
        if HighMobilityManager.shared.hasAccessCertificates {
            let controller = UIAlertController(title: "", message: "Would you like to unlink the vehicle?", preferredStyle: .actionSheet)

            controller.addAction(.init(title: "Cancel", style: .cancel, handler: nil))
            controller.addAction(.init(title: "Unlink", style: .destructive, handler: { _ in
                HighMobilityManager.shared.clearDatabase()

                self.updateLinkButton(isLinked: false)
                self.enableInteractions(false)
            }))

            controller.popoverPresentationController?.sourceView = sender

            present(controller, animated: true, completion: nil)
        }
        else {
            openOAuthURL()
        }
    }


    // MARK: Methods

    func refreshVehicleStatus() {
        HighMobilityManager.shared.refreshVehicleStatus()
    }


    // MARK: UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        configureButton(connectButton)
        configureButton(linkButton)
        enableInteractions(HighMobilityManager.shared.hasAccessCertificates)
        updateLinkButton(isLinked: HighMobilityManager.shared.hasAccessCertificates)

        HighMobilityManager.shared.isBluetoothConnection = connectionMethodSegment.selectedSegmentIndex == 0

        #if targetEnvironment(simulator)
            connectionMethodSegment.selectedSegmentIndex = 1
            connectionMethodSegment.isEnabled = false
        #endif
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        HighMobilityManager.shared.disconnectBluetooth()

        // This should happen through something else
        connectButton.setTitle("CONNECT", for: .normal)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        navigationItem.prompt = nil
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        navigationItem.backBarButtonItem?.title = (segue.destination is CommandsViewController) ? "Back" : "Disconnect"

        // Send the (tableview-) controller the latest "data"
        guard let deviceUpdatable = segue.destination as? DeviceUpdatable,
            let debugTree = sender as? DebugTree else {
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
            case .certificatesDownloaded:
                displayText(nil)
                enableInteractions(true)
                updateLinkButton(isLinked: true)

            case .disconnected:
                enableInteractions(true)
                popToRootViewController()

            case .broadcasting(let name):
                connectButton.setTitle("DISCONNECT", for: .normal)

                displayText("Broadcasting... \(name)")
                enableInteractions(true)

            case .connected:
                displayText("Connecting...")

            case .authenticated:
                displayText("Authenticated, getting VS...")
                HighMobilityManager.shared.refreshVehicleStatus()
            }
        }
    }

    func deviceReceived(debugTree: DebugTree) {
        // Push the 1st TableViewController if none present
        guard let count = navigationController?.viewControllers.count, count == 1 else {
            return
        }

        performSegue(withIdentifier: "showTableViewController", sender: debugTree)
    }
}

extension ConnectViewController: OAuthUpdatable {

    func oauthReceivedRedirect(_ result: OAuthManager.RedirectResult) {
        var text: String

        switch result {
        case .error(reason: let reason, state: let state):
            text = "ATC error: " + reason

            if let state = state {
                text += ", state: " + state
            }

        case .successful(accessTokenCode: let tokenCode, state: let state):
            text = "ATC success: " + tokenCode

            if let state = state {
                text += ", state: " + state
            }

            HighMobilityManager.shared.downloadAccessCertificates(accessTokenCode: tokenCode, completion: deviceChanged)

        default:
            text = "Access Token Code Tailor Error"
        }

        displayText(text)
    }
}

private extension ConnectViewController {

    func configureButton(_ button: UIButton) {
        button.layer.borderColor = view.tintColor.cgColor
        button.layer.borderWidth = 1.0
        button.layer.cornerRadius = 4.0
        button.layer.masksToBounds = true
    }

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

    func openOAuthURL() {
        if HighMobilityManager.shared.isRunningDebug {
            HighMobilityManager.shared.downloadDebugCertificates()
        }
        else {
            guard let url = HighMobilityManager.shared.oauthURL else {
                return print("Missing OAuthURL")
            }

            UIApplication.shared.open(url, options: [:], completionHandler: nil)

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

    func updateLinkButton(isLinked: Bool) {
        let text = isLinked ? "UNLINK VEHICLE" : "LINK VEHICLE"

        OperationQueue.main.addOperation {
            self.linkButton.setTitle(text, for: .normal)
        }
    }
}
