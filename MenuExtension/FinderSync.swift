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
	let keyName = "MenuItems"
	var menuItems = [[String]]()
	var completePath = String()

	func loadMenuItems() -> [[String]] {
		if let defaults = UserDefaults.standard.object(forKey: keyName) {
			return defaults as! [[String]]
		} else {
			return [[String]]()
		}
	}

	func loadMountPoints() -> [URL] {
		let paths = FileManager().mountedVolumeURLs(includingResourceValuesForKeys: nil, options: [])
		return paths ?? [URL(fileURLWithPath: "/")]
	}

	override func observeValue(forKeyPath keyPath: String?, of _: Any?, change _: [NSKeyValueChangeKey: Any]?, context _: UnsafeMutableRawPointer?) {
		if keyPath != keyName {
			return
		}
		menuItems = loadMenuItems()
	}

	@objc func volNotifyHandler(notification _: NSNotification) {
		FIFinderSyncController.default().directoryURLs = Set(loadMountPoints())
	}

	override init() {
		super.init()
		menuItems = loadMenuItems()
		FIFinderSyncController.default().directoryURLs = Set(loadMountPoints())
		let ud = UserDefaults.standard
		ud.addObserver(self, forKeyPath: keyName, options: .new, context: nil)
		let nc = NSWorkspace.shared.notificationCenter
		nc.addObserver(self, selector: #selector(volNotifyHandler), name: NSWorkspace.didMountNotification, object: nil)
		nc.addObserver(self, selector: #selector(volNotifyHandler), name: NSWorkspace.didUnmountNotification, object: nil)
		nc.addObserver(self, selector: #selector(volNotifyHandler), name: NSWorkspace.didRenameVolumeNotification, object: nil)
	}

	// MARK: - Menu and toolbar item support

	func newMenuItem(title: String, action: Selector?, isEnabled: Bool? = true, tag: NSInteger? = -1) -> NSMenuItem {
		let menuItem = NSMenuItem(title: title, action: action, keyEquivalent: "")
		menuItem.isEnabled = isEnabled!
		menuItem.tag = tag!
		return menuItem
	}

	func getPath() -> [String]? {
		guard var path = FIFinderSyncController.default().targetedURL() else {
			return nil
		}
		if let selectedItems = FIFinderSyncController.default().selectedItemURLs() {
			if selectedItems.count == 1,
				let first = selectedItems.first {
				if first.hasDirectoryPath {
					path = first
				} else {
					path = first.deletingLastPathComponent()
				}
			} else if selectedItems.count > 1 {
				return nil
			}
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
		guard let path = getPath() else {
			return menu
		}
		completePath = path[0]
		menu.addItem(newMenuItem(title: path[1], action: #selector(menuAction), isEnabled: false))
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
