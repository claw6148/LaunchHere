//
//  FinderSync.swift
//  MenuExtension
//
//  Created by Chileung Law on 2019/11/14.
//  Copyright © 2019 Chileung Law. All rights reserved.
//

import Cocoa
import FinderSync

class FinderSync: FIFinderSync {
	var menuCommands = [String: String]()

	func loadMenuItems() -> [[String]] {
		let defaults = UserDefaults.standard.object(forKey: "MenuItems")
		if defaults == nil {
			return [[String]]()
		}
		return defaults as! [[String]]
	}

	func loadMountPoints() {
		let keys: [URLResourceKey] = [.volumeNameKey, .volumeIsRemovableKey, .volumeIsEjectableKey]
		let paths = FileManager().mountedVolumeURLs(includingResourceValuesForKeys: keys, options: [])
		FIFinderSyncController.default().directoryURLs = Set(paths!)
	}

	override init() {
		super.init()
		loadMountPoints()
	}

	// MARK: - Menu and toolbar item support

	override var toolbarItemName: String {
		return "Menu"
	}

	override var toolbarItemToolTip: String {
		return ""
	}

	override var toolbarItemImage: NSImage {
		return NSImage(named: NSImage.applicationIconName)!
	}

	override func menu(for menuKind: FIMenuKind) -> NSMenu {
		loadMountPoints()
		let menu = NSMenu(title: "")
		if menuKind == .contextualMenuForContainer || menuKind == .toolbarItemMenu {
			let menuItems = loadMenuItems()
			if menuItems.count == 0 {
				let noMenuItem = NSMenuItem(title: "No Menu", action: nil, keyEquivalent: "")
				noMenuItem.isEnabled = false
				menu.addItem(noMenuItem)
			} else {
				for menuItem in menuItems {
					menu.addItem(withTitle: menuItem[0], action: #selector(menuAction), keyEquivalent: "")
					menuCommands[menuItem[0]] = menuItem[1]
				}
			}
		}
		return menu
	}

	@IBAction func menuAction(_ sender: NSMenuItem) {
		let proc = Process()
		proc.environment = ProcessInfo.processInfo.environment
		proc.currentDirectoryPath = FIFinderSyncController.default().targetedURL()?.path ?? "~/"
		proc.launchPath = "/bin/sh"
		proc.arguments = ["-c", menuCommands[sender.title]!]
		proc.launch()
	}
}