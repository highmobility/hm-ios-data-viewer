//
//  TableViewController.swift
//  Data Viewer
//
//  Created by Mikk Rätsep on 03/05/2018.
//  Copyright © 2018 High-Mobility OÜ. All rights reserved.
//

import HMUtilities
import UIKit


class TableViewController: UITableViewController {

    private var groups: [DebugTree] = []


    // MARK: IBOutlets

    @IBOutlet var hexKeyboardView: HexKeyboardView!
    @IBOutlet var refreshButton: UIBarButtonItem!


    // MARK: IBActions

    @IBAction func refreshButtonTapped(_ sender: UIBarButtonItem) {
        connectionViewController?.refreshVehicleStatus()
    }

    @IBAction func sendCommandTapped(_ sender: UIBarButtonItem) {
        presentSendCommandAlert()
    }


    // MARK: UITableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        return groups.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch groups[section] {
        case .leaf:
            return 1

        case .node(label: _, nodes: let nodes):
            return nodes.count
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        guard let node = node(indexPath) else {
            return cell
        }
        
        if case .leaf = node {
            let components = node.label.components(separatedBy: "=")
            
            cell.textLabel?.text = components.first
            cell.detailTextLabel?.text = components.last
            cell.accessoryType = .none
        }
        else {
            cell.textLabel?.text = node.label
            cell.detailTextLabel?.text = nodesSubTypeValue(node)
            cell.accessoryType = .disclosureIndicator
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch groups[section] {
        case .leaf:
            return nil

        case .node(let label, _):
            return label
        }
    }


    // MARK: UITableViewDelegate

    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        guard let node = node(indexPath),
            case .node = node else {
                return nil
        }

        return indexPath
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let node = node(indexPath) else {
            return
        }

        displaySubController(node: node)
    }
}

extension TableViewController: DeviceUpdatable {

    func deviceChanged(to result: Result<ConnectionState>) {
        // Naah
    }

    func deviceReceived(debugTree: DebugTree) {
        var matchesTitle: (DebugTree) -> Bool {
            return {
                return (self.navigationItem.title == $0.label) &&
                    (self.navigationItem.prompt == self.nodesSubTypeValue($0))
            }
        }

        // Check if this is a DebugTree for this controller or not
        if self.groups.isEmpty || matchesTitle(debugTree) {
            matchingDebugTreeReceived(debugTree)
        }
        else if let nodes = debugTree.nodes {
            let sub2Nodes = nodes.filter(nodeFilterFunction).reduce(nodes) { $0 + ($1.nodes ?? []) }

            guard let matchingNode = sub2Nodes.first(where: matchesTitle) else {
                return sub2Nodes.forEach { self.deviceReceived(debugTree: $0) }
            }

            matchingDebugTreeReceived(matchingNode)
        }
    }
}

private extension TableViewController {

    var node: (IndexPath) -> DebugTree? {
        return {
            guard let nodes = self.groups[$0.section].nodes else {
                return nil
            }

            return nodes[$0.row]
        }
    }

    var nodeFilterFunction: (DebugTree) -> Bool {
        return {
            !$0.label.hasPrefix("*") &&
                !$0.label.contains(" = nil")
        }
    }


    // MARK: Methods

    func animateDataReceived() {
        UIView.animate(withDuration: 0.2, delay: 0.0, options: [.curveEaseInOut], animations: {
            self.navigationController?.navigationBar.backgroundColor = self.view.tintColor
        }, completion: { _ in
            UIView.animate(withDuration: 0.2, delay: 0.0, options: [.curveEaseInOut], animations: {
                self.navigationController?.navigationBar.backgroundColor = nil
            }, completion: nil)
        })
    }

    func displaySubController(node: DebugTree) {
        guard let controller = storyboard?.instantiateViewController(withIdentifier: "TableViewControllerID") as? TableViewController else {
            return
        }

        controller.deviceReceived(debugTree: node)

        navigationController?.pushViewController(controller, animated: true)
    }

    func matchingDebugTreeReceived(_ debugTree: DebugTree) {
        navigationItem.title = debugTree.label
        navigationItem.prompt = nodesSubTypeValue(debugTree)

        animateDataReceived()
        updateGroups(debugTree: debugTree)

        tableView.reloadData()
    }

    func nodesSubTypeValue(_ node: DebugTree) -> String? {
        if let driverNumber = node.subPropertyValue(named: "driverNumber", filterFunction: nodeFilterFunction) {
            return driverNumber
        }
        else if let locationValue = node.subPropertyValue(named: "location", filterFunction: nodeFilterFunction) {
            return locationValue
        }
        else if let nameValue = node.subPropertyValue(named: "name", filterFunction: nodeFilterFunction), node.label != "VehicleStatus" {
            return nameValue
        }
        else if let positionValue = node.subPropertyValue(named: "position", filterFunction: nodeFilterFunction) {
            return positionValue
        }
        else {
            return nil
        }
    }

    func presentSendCommandAlert() {
        let alertController = UIAlertController(title: "", message: "Send a custom command to the connected device", preferredStyle: .alert)
        let sendAction = UIAlertAction(title: "Send", style: .default) { _ in
            guard let bytes = alertController.textFields?.first?.text?.bytes, bytes.count > 0 else {
                return
            }

            HighMobilityManager.shared.sendCommand(bytes, name: "Custom")
        }

        alertController.addAction(sendAction)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        alertController.addTextField {
            $0.inputView = self.hexKeyboardView

            self.hexKeyboardView.textfield = $0
        }

        present(alertController, animated: true, completion: nil)
    }

    func updateGroups(debugTree: DebugTree) {
        // Filter the nodes
        guard let nodes = debugTree.nodes?.filter(nodeFilterFunction) else {
            return self.groups = []
        }

        // Extract different "types" of values (just 2 atm)
        let properties: [DebugTree] = nodes.compactMap {
            guard case .leaf = $0 else {
                return nil
            }

            return $0
        }

        let subNodes: [DebugTree] = nodes.compactMap {
            guard case .node = $0 else {
                return nil
            }

            return $0
        }

        var groups: [DebugTree] = []

        // Check what to add
        if properties.count > 0 {
            groups.append(DebugTree.node(label: "Properties", nodes: properties))
        }

        if subNodes.count > 0 {
            groups.append(contentsOf: subNodes)
        }

        // Return alphabetically
        self.groups = groups.sorted { $0.label < $1.label }
    }
}
