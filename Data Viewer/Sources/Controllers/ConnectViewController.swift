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
    @IBOutlet var loginButton: UIButton!


    // MARK: IBActions

    @IBAction func connectButtonTapped(_ sender: UIButton) {
        loginButton.isEnabled = false

        if isBluetoothSelected {
            enableInteractions(false)

            do {
                try HighMobilityManager.shared.startBluetoothBroadcasting()
            }
            catch {
                loginButton.isEnabled = true

                displayText("Failed to start Bluetooth broadcasting: \(error)")
            }
        }
        else {
            HighMobilityManager.shared.refreshVehicleStatus(usingBluetooth: false)
        }
    }

    @IBAction func loginButtonTapped(_ sender: UIButton) {
        if HighMobilityManager.shared.hasAccessCertificates {
            let controller = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

            controller.addAction(.init(title: "Cancel", style: .cancel, handler: nil))
            controller.addAction(.init(title: "Log out", style: .destructive, handler: { _ in
                HighMobilityManager.shared.clearDatabase()

                self.updateLoginButton(loggedIn: false)
                self.enableInteractions(false)
            }))

            present(controller, animated: true, completion: nil)
        }
        else {
            openOAuthURL()
        }
    }


    // MARK: Methods

    func refreshVehicleStatus() {
        HighMobilityManager.shared.refreshVehicleStatus(usingBluetooth: isBluetoothSelected)
    }


    // MARK: UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        configureButton(connectButton)
        configureButton(loginButton)
        enableInteractions(HighMobilityManager.shared.hasAccessCertificates)
        updateLoginButton(loggedIn: HighMobilityManager.shared.hasAccessCertificates)

        #if targetEnvironment(simulator)
            connectionMethodSegment.selectedSegmentIndex = 1
            connectionMethodSegment.isEnabled = false
        #endif
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        HighMobilityManager.shared.disconnectBluetooth()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        loginButton.isEnabled = true
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
                updateLoginButton(loggedIn: true)

            case .disconnected:
                enableInteractions(true)
                popToRootViewController()

            case .broadcasting(let name):
                displayText("Broadcasting... \(name)")

            case .connected:
                displayText("Connecting...")

            case .authenticated:
                displayText("Authenticated, getting VS...")
                HighMobilityManager.shared.refreshVehicleStatus(usingBluetooth: true)
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

    var isBluetoothSelected: Bool {
        return connectionMethodSegment.selectedSegmentIndex == 0
    }


    // MARK: Methods

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
        guard let url = HighMobilityManager.shared.oauthURL else {
            return print("Missing OAuthURL")
        }

        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    func popToRootViewController() {
        OperationQueue.main.addOperation {
            guard let viewControllers = self.navigationController?.viewControllers, viewControllers.count > 1 else {
                return
            }

            self.navigationController?.popToRootViewController(animated: true)
        }
    }

    func updateLoginButton(loggedIn: Bool) {
        let text = loggedIn ? "LOG OUT" : "LOGIN"

        OperationQueue.main.addOperation {
            self.loginButton.setTitle(text, for: .normal)
        }
    }
}
