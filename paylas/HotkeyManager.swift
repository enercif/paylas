//
//  HotkeyManager.swift
//  paylas
//
//  Registers a global keyboard shortcut (default ⌃⌥⇧2) that triggers the
//  section selector even while Paylas is in the background. Carbon's
//  RegisterEventHotKey is used deliberately instead of an NSEvent global
//  monitor because it works system-wide without requiring Input Monitoring
//  permission.
//

import AppKit
import Carbon.HIToolbox

final class HotkeyManager {
    static let shared = HotkeyManager()

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private var action: (() -> Void)?

    private let signature: OSType = 0x50594C53 // 'PYLS'
    private let keyCode: UInt32 = UInt32(kVK_ANSI_2)
    private let modifiers: UInt32 = UInt32(controlKey) | UInt32(optionKey) | UInt32(shiftKey)

    private init() {}

    func start(action: @escaping () -> Void) {
        self.action = action
        if UserDefaults.standard.bool(forKey: AppSettings.hotkeyEnabledKey) {
            register()
        }
    }

    func setEnabled(_ enabled: Bool) {
        if enabled {
            register()
        } else {
            unregister()
        }
    }

    private func register() {
        guard hotKeyRef == nil else { return }

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, eventRef, userData in
            guard let userData, let eventRef else { return noErr }
            var pressedHotKeyID = EventHotKeyID()
            GetEventParameter(eventRef, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil, MemoryLayout<EventHotKeyID>.size, nil, &pressedHotKeyID)
            let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
            if pressedHotKeyID.id == 1 {
                manager.action?()
            }
            return noErr
        }, 1, &eventType, Unmanaged.passUnretained(self).toOpaque(), &eventHandlerRef)

        let hotKeyID = EventHotKeyID(signature: signature, id: 1)
        RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
    }

    private func unregister() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
        if let eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
            self.eventHandlerRef = nil
        }
    }
}
