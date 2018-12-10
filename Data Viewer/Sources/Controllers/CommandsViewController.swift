//
//  CommandsViewController.swift
//  Data Viewer
//
//  Created by Mikk Rätsep on 08/05/2018.
//  Copyright © 2018 High-Mobility OÜ. All rights reserved.
//

import HMUtilities
import UIKit


class CommandsViewController: UITableViewController {

    let searchController = UISearchController(searchResultsController: nil)

    var filteredCommands: [CommandInfo] = []

    lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()

        formatter.timeStyle = .medium

        return formatter
    }()


    // MARK: UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        filteredCommands = CommandsManager.shared.commands

        configureSearchController()
    }


    // MARK: UITableViewDataSource

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredCommands.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
        let command = filteredCommands[indexPath.row]

        cell.label(tagged: 100)?.text = command.name
        cell.label(tagged: 101)?.text = "0x" + command.bytes.hex
        cell.label(tagged: 102)?.text = dateFormatter.string(from: command.date)
        cell.label(tagged: 103)?.text = commandDirectionArrow(command)

        return cell
    }


    // MARK: UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        UIPasteboard.general.string = filteredCommands[indexPath.row].bytes.hex
    }
}

extension CommandsViewController: UISearchBarDelegate {

    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.selectedScopeButtonIndex = 1
    }

    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        refreshTableView(commands: filteredCommands(scopeIdx: selectedScope, text: searchBar.text))
    }
}

extension CommandsViewController: UISearchResultsUpdating {

    func updateSearchResults(for searchController: UISearchController) {
        if searchController.isActive {
            let searchBar = searchController.searchBar

            refreshTableView(commands: filteredCommands(scopeIdx: searchBar.selectedScopeButtonIndex, text: searchBar.text))
        }
        else {
            refreshTableView(commands: CommandsManager.shared.commands)
        }
    }
}

private extension CommandsViewController {

    var commandDirectionArrow: (CommandInfo) -> String {
        return { $0.isSent ? "↑" : "↓" }
    }


    // MARK: Methods

    func configureSearchController() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false

        searchController.searchBar.delegate = self
        searchController.searchBar.placeholder = "Command name"
        searchController.searchBar.scopeButtonTitles = ["SENT", "ALL", "RECEIVED"]
        searchController.searchBar.selectedScopeButtonIndex = 1
        searchController.searchBar.tintColor = view.tintColor

        navigationItem.searchController = searchController
    }

    func filteredCommands(scopeIdx: Int, text: String?) -> [CommandInfo] {
        let commands: [CommandInfo]

        // Scope
        switch scopeIdx {
        case 0:     commands = CommandsManager.shared.commands.filter { $0.isSent }
        case 2:     commands = CommandsManager.shared.commands.filter { !$0.isSent }
        default:    commands = CommandsManager.shared.commands
        }

        // Text
        if let text = text, !text.isEmpty {
            return commands.filter { $0.name.localizedCaseInsensitiveContains(text) }
        }
        else {
            return commands
        }
    }

    func refreshTableView(commands: [CommandInfo]) {
        filteredCommands = commands

        tableView.beginUpdates()
        tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
        tableView.endUpdates()
    }
}
