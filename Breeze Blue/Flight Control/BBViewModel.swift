//
//  ViewModel.swift
//  BreezeBlue client
//
//  Created by Martin Eberl on 23.01.17.
//  Copyright © 2017 Bitcraze. All rights reserved.
//

import Foundation

protocol BBViewModelDelegate: class {
    func signalUpdate()
    func signalFailed(with title: String, message: String?)
}

final class BBViewModel {
    weak var delegate: BBViewModelDelegate?
    let leftJoystickProvider: BBJoystickViewModel
    let rightJoystickProvider: BBJoystickViewModel

    private var motionLink: BBMotionLink?
//    private var breezeblue: BreezeBlue?
    //=======NEW=======
    public var breezeblue: BreezeBlue?
    //=======NEW=======
    private var sensitivity: Sensitivity = .slow
    private var controlMode: ControlMode = ControlMode.current ?? .mode1

    fileprivate(set) var progress: Float = 0
    fileprivate(set) var topButtonTitle: String

    init() {
        topButtonTitle = "Connect"

        leftJoystickProvider = BBJoystickViewModel()
        rightJoystickProvider = BBJoystickViewModel(deadbandX: 0.1, vLabelLeft: true)

        leftJoystickProvider.add(observer: self)
        rightJoystickProvider.add(observer: self)

        breezeblue = BreezeBlue(delegate: self)
        loadDefaults()
    }

    deinit {
        leftJoystickProvider.remove(observer: self)
        rightJoystickProvider.remove(observer: self)
    }

    var leftXTitle: String? {
        return title(at: 0)
    }
    var rightXTitle: String? {
        return title(at: 2)
    }
    var leftYTitle: String? {
        return title(at: 1)
    }
    var rightYTitle: String? {
        return title(at: 3)
    }

    var bothThumbsOnJoystick: Bool {
        return leftJoystickProvider.activated && rightJoystickProvider.activated
    }

    lazy var settingsViewModel: BBSettingsViewModel? = {
//        guard let bluetoothLink = self.breezeblue?.bluetoothLink else {
//            return nil
//        }
        let settings = BBSettingsViewModel(sensitivity: self.sensitivity, controlMode: self.controlMode)
        settings.add(observer: self)
        return settings
    }()

    // MARK: - Public Methods

    func loadSettings() {

    }

//    func connect() {
//        breezeblue?.connect(nil)
//    }

    // MARK: - Private Methods
    private func title(at index: Int) -> String? {
        guard controlMode.titles.indices.contains(index) else { return nil }

        return controlMode.titles[index]
    }

    private func startMotionUpdate() {
        if motionLink == nil {
            motionLink = BBMotionLink()
        }
        motionLink?.startDeviceMotionUpdates(nil)
        motionLink?.startAccelerometerUpdates(nil)
    }

    private func stopMotionUpdate() {
        motionLink?.stopDeviceMotionUpdates()
        motionLink?.stopAccelerometerUpdates()
    }

    private func loadDefaults() {
        guard let url = Bundle.main.url(forResource: "DefaultPreferences", withExtension: "plist"),
            let defaultPrefs = NSDictionary(contentsOf: url) else {
                return
        }
        let defaults = UserDefaults.standard
        defaults.register(defaults: defaultPrefs as! [String : Any])
        defaults.synchronize()

        updateSettings()
    }

    func updateSettings() {
        if controlMode == .tilt,
            BBMotionLink().canAccessMotion {
            startMotionUpdate()
        }
        else {
            stopMotionUpdate()
        }

        applyCommander()
    }

    fileprivate func calibrateMotionIfNeeded() {
        if (leftJoystickProvider.touchesChanged || rightJoystickProvider.touchesChanged)
            && bothThumbsOnJoystick && controlMode == .tilt {
            motionLink?.calibrate()
        }
    }

    fileprivate func changed(controlMode: ControlMode) {
        self.controlMode = controlMode
        updateSettings()
    }

    private func applyCommander() {
        breezeblue?.commander = controlMode.commander(
            leftJoystick: leftJoystickProvider,
            rightJoystick: rightJoystickProvider,
            motionLink: motionLink,
            settings: sensitivity.settings)
    }

    fileprivate func updateWith(state: BreezeBlueState) {
        topButtonTitle = "Cancel"
        switch state {
        case .idle:
            progress = 0
            topButtonTitle = "Connect"
            break
        case .scanning:
            progress = 0
            break
        case .connecting:
            progress = 0.25
            break
        case .services:
            progress = 0.5
            break
        case .characteristics:
            progress = 0.75
            break
        case .connected:
            progress = 1
            break
        }
    }
}

extension BBViewModel: BBJoystickViewModelObserver {
    func didUpdateState() {
        calibrateMotionIfNeeded()

        delegate?.signalUpdate()
    }
}

extension BBViewModel: BBSettingsViewModelObserver {
    func didUpdate(controlMode: ControlMode) {
        changed(controlMode: controlMode)
    }
}

//MARK: - BreezeBlue
extension BBViewModel: BreezeBlueDelegate {
    func didSend() {

    }

    func didUpdate(state: BreezeBlueState) {
        updateWith(state: state)
        delegate?.signalUpdate()
    }

    func didFail(with title: String, message: String?) {
        delegate?.signalFailed(with: title, message: message)
    }
}

