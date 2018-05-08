//
//  TableViewController.swift
//  Data Viewer
//
//  Created by Mikk Rätsep on 03/05/2018.
//  Copyright © 2018 High-Mobility OÜ. All rights reserved.
//

import AutoAPI
import UIKit


class TableViewController: UITableViewController {

    static let identifier = "TableViewControllerID"

    private var debugTree: AutoAPI.DebugTree?


    // MARK: IBOutlets

    @IBOutlet var refreshButton: UIBarButtonItem!


    // MARK: IBActions

    @IBAction func refreshButtonTapped(_ sender: UIBarButtonItem) {
        connectionViewController?.refreshVehicleStatus()
    }


    // MARK: UITableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        guard let debugTree = debugTree else {
            return 0
        }

        return groups(debugTree).count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let debugTree = debugTree else {
            return 0
        }

        switch groups(debugTree)[section] {
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
            cell.detailTextLabel?.text = nil
            cell.accessoryType = .disclosureIndicator
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard var debugTree = debugTree else {
            return nil
        }

        debugTree = groups(debugTree)[section]

        switch debugTree {
        case .leaf:
            return nil

        case .node:
            return debugTree.label
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

    func deviceReceived(debugTree: AutoAPI.DebugTree) {
        if isThisControllersDebugTree(debugTree) {
            matchingDebugTreeReceived(debugTree)
        }
        else if let nodes = debugTree.nodes {
            let sub2Nodes = nodes.reduce(nodes) { $0 + ($1.nodes ?? []) }

            guard let matchingNode = sub2Nodes.first(where: { self.isThisControllersDebugTree($0) }) else {
                return sub2Nodes.forEach { self.deviceReceived(debugTree: $0) }
            }

            matchingDebugTreeReceived(matchingNode)
        }
    }
}

private extension TableViewController {

    var groups: (AutoAPI.DebugTree) -> [AutoAPI.DebugTree] {
        return {
            guard let nodes = $0.nodes?.filter({ !$0.label.hasPrefix("*") }) else {
                return []
            }

            // Extract different "types" of values (just 2 atm)
            let properties: [AutoAPI.DebugTree] = nodes.compactMap {
                guard case .leaf = $0 else {
                    return nil
                }

                return $0
            }

            let subNodes: [AutoAPI.DebugTree] = nodes.compactMap {
                guard case .node = $0 else {
                    return nil
                }

                return $0
            }

            var groups: [AutoAPI.DebugTree] = []

            // Check what to add
            if properties.count > 0 {
                groups.append(AutoAPI.DebugTree.node(label: "Properties", nodes: properties))
            }

            if subNodes.count > 0 {
                groups.append(contentsOf: subNodes)
            }

            // Return alphabetically
            return groups.sorted { $0.label < $1.label }
        }
    }

    var isThisControllersDebugTree: (AutoAPI.DebugTree) -> Bool {
        return {
            return (self.debugTree == nil) || (self.debugTree?.label == $0.label)
        }
    }

    var node: (IndexPath) -> AutoAPI.DebugTree? {
        return {
            guard let debugTree = self.debugTree,
                let nodes = self.groups(debugTree)[$0.section].nodes else {
                    return nil
            }

            return nodes[$0.row]
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

    func displaySubController(node: AutoAPI.DebugTree) {
        guard let controller = storyboard?.instantiateViewController(withIdentifier: "TableViewControllerID") as? TableViewController else {
            return
        }

        controller.deviceReceived(debugTree: node)

        navigationController?.pushViewController(controller, animated: true)
    }

    func matchingDebugTreeReceived(_ node: AutoAPI.DebugTree) {
        debugTree = node

        navigationItem.title = node.label

        tableView.beginUpdates()
        tableView.reloadSections(IndexSet(integersIn: 0..<tableView.numberOfSections), with: .automatic)
        tableView.endUpdates()

        animateDataReceived()
    }
}
