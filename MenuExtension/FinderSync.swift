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
	var menuItems = [[String]]()
	var completePath = ""

	func loadMenuItems() {
		let defaults = UserDefaults.standard.object(forKey: "MenuItems")
		if defaults == nil {
			menuItems = [[String]]()
			return
		}
		menuItems = defaults as! [[String]]
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

	func newMenuItem(title: String, action: Selector?, isEnabled: Bool? = true, tag: NSInteger? = -1) -> NSMenuItem {
		let menuItem = NSMenuItem(title: title, action: action, keyEquivalent: "")
		menuItem.isEnabled = isEnabled!
		menuItem.tag = tag!
		return menuItem
	}

	func getPath() -> [String]? {
		var path = FIFinderSyncController.default().targetedURL()!
		let selectedItems = FIFinderSyncController.default().selectedItemURLs()
		if selectedItems != nil, selectedItems!.count == 1, selectedItems?.first?.hasDirectoryPath == true {
			path = (selectedItems?.first!)!
		}
		return [path.path, path.lastPathComponent]
	}

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
		let menu = NSMenu(title: "")
		if menuKind != .contextualMenuForContainer, menuKind != .toolbarItemMenu, menuKind != .contextualMenuForItems {
			return menu
		}
		let path = getPath()
		if path == nil {
			return menu
		}
		loadMenuItems()
		loadMountPoints()
		completePath = path![0]
		menu.addItem(newMenuItem(title: path![1], action: #selector(menuAction), isEnabled: false))
		var itemsIndex = 0
		for menuItem in menuItems {
			menu.addItem(newMenuItem(
				title: menuItem[0],
				action: #selector(menuAction),
				tag: itemsIndex
			))
			itemsIndex += 1
		}
		return menu
	}

	@IBAction func menuAction(_ menuItem: NSMenuItem) {
		if menuItem.tag < 0 {
			return
		}
		let proc = Process()
		proc.environment = ProcessInfo.processInfo.environment
		proc.currentDirectoryPath = completePath
		proc.launchPath = "/bin/bash"
		proc.arguments = ["-c", menuItems[menuItem.tag][1]]
		proc.launch()
	}
}