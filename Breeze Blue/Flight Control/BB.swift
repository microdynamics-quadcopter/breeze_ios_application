//
//  BreezeBlue.swift
//  BreezeBlue client
//
//  Created by Martin Eberl on 15.07.16.
//  Copyright © 2016 Bitcraze. All rights reserved.
//

import UIKit

protocol BreezeBlueCommander {
    var pitch: Float { get }
    var roll: Float { get }
    var thrust: Float { get }
    var yaw: Float { get }

    func prepareData()
}

enum BreezeBlueHeader: UInt8 {
    case commander = 0x30
}

enum BreezeBlueState {
    case idle, connected , scanning, connecting, services, characteristics
}

protocol BreezeBlueDelegate {
    func didSend()
    func didUpdate(state: BreezeBlueState)
    func didFail(with title: String, message: String?)
}

open class BreezeBlue: NSObject {

    private(set) var state:BreezeBlueState {
        didSet {
            delegate?.didUpdate(state: state)
        }
    }
    private var timer:Timer?
    private var delegate: BreezeBlueDelegate?
//    private(set) var bluetoothLink:BluetoothLink!

    var commander: BreezeBlueCommander?

    init(delegate: BreezeBlueDelegate?) {

        state = .idle
        self.delegate = delegate

//        self.bluetoothLink = bluetoothLink
        super.init()

//        bluetoothLink?.onStateUpdated{[weak self] (state) in
//            if state.isEqual(to: "idle") {
//                self?.state = .idle
//            } else if state.isEqual(to: "connected") {
//                self?.state = .connected
//            } else if state.isEqual(to: "scanning") {
//                self?.state = .scanning
//            } else if state.isEqual(to: "connecting") {
//                self?.state = .connecting
//            } else if state.isEqual(to: "services") {
//                self?.state = .services
//            } else if state.isEqual(to: "characteristics") {
//                self?.state = .characteristics
//            }
//        }

        startTimer()
    }

//    func connect(_ callback:((Bool) -> Void)?) {
//        guard state == .idle else {
//            self.disconnect()
//            return
//        }
//
//        self.bluetoothLink.connect(nil, callback: {[weak self] (connected) in
//            callback?(connected)
//            guard connected else {
//                if self?.timer != nil {
//                    self?.timer?.invalidate()
//                    self?.timer = nil
//                }
//
//                var title:String
//                var body:String?
//
//                // Find the reason and prepare a message
//                if self?.bluetoothLink.getError() == "Bluetooth disabled" {
//                    title = "Bluetooth disabled"
//                    body = "Please enable Bluetooth to connect a BreezeBlue"
//                } else if self?.bluetoothLink.getError() == "Timeout" {
//                    title = "Connection timeout"
//                    body = "Could not find BreezeBlue"
//                } else {
//                    title = "Error";
//                    body = self?.bluetoothLink.getError()
//                }
//
//                self?.delegate?.didFail(with: title, message: body)
//                return
//            }
//
//            self?.startTimer()
//        })
//    }

//    func disconnect() {
//        bluetoothLink.disconnect()
//        stopTimer()
//    }

    // MARK: - Private Methods

    private func startTimer() {
        stopTimer()

        self.timer = Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(self.updateData), userInfo:nil, repeats:true)
    }

    private func stopTimer() {
        if timer != nil {
            timer?.invalidate()
            timer = nil
        }
    }

    @objc private func updateData(_ timter:Timer){
        guard timer != nil, let commander = commander else {
            return
        }

        commander.prepareData()
//        sendFlightData(commander.roll, pitch: commander.pitch, thrust: commander.thrust, yaw: commander.yaw)
    }

//    private func sendFlightData(_ roll:Float, pitch:Float, thrust:Float, yaw:Float) {
//        let commandPacket = CommanderPacket(header: BreezeBlueHeader.commander.rawValue, roll: roll, pitch: pitch, yaw: yaw, thrust: UInt16(thrust))
//        let data = CommandPacketCreator.data(from: commandPacket)
//        bluetoothLink.sendPacket(data!, callback: nil)
//    }
}

