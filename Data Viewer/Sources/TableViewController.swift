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

    var debugTree: DebugTree?


    // MARK: Methods

    func receivedDebugTree(_ debugTree: DebugTree) {
        guard (self.debugTree?.label == debugTree.label) || (self.debugTree == nil) else {
            return
        }

        self.debugTree = debugTree
        self.navigationItem.title = debugTree.label

        tableView.reloadData()
    }


    // MARK: UITableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        return groups.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let debugTree = groups[section]

        switch debugTree {
        case .leaf:
            return 1

        case .node(label: _, nodes: let nodes):
            return nodes.count
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "tableViewCellID", for: indexPath)

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
        let debugTree = groups[section]

        switch debugTree {
        case .leaf:
            return nil

        case .node:
            return debugTree.label
        }
    }

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

        guard let controller = storyboard?.instantiateViewController(withIdentifier: "TableViewControllerID") as? TableViewController else {
            return
        }

        controller.receivedDebugTree(node)

        navigationController?.pushViewController(controller, animated: true)
    }
}

private extension TableViewController {

    var groups: [DebugTree] {
        guard let debugTree = debugTree else {
            return []
        }

        guard case .node(label: _, nodes: var nodes) = debugTree else {
            return []
        }

        nodes = nodes.filter { !$0.label.hasPrefix("*") }

        // Filter to sub-groups
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

        let combined = [DebugTree.node(label: "Properties", nodes: properties)] + subNodes

        return combined.sorted { $0.label < $1.label }
    }

    var node: (IndexPath) -> DebugTree? {
        return {
            guard case .node(label: _, nodes: let nodes) = self.groups[$0.section] else {
                return nil
            }

            return nodes[$0.row]
        }
    }
}
