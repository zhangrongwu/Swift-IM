//
//  SESocketManager.swift
//  Swift-IM
//
//  Created by zhangrongwu on 2017/2/20.
//  Copyright © 2017年 bocom. All rights reserved.
//  项目与框架连接模块

import UIKit
import Starscream
import Alamofire
class SESocketManager: NSObject, WebSocketDelegate {
    
    static let instance = SESocketManager()
    
    var connectStatus = 0 //connect status：1 connect，-1 not connect，0 connecting
    
    var  beatTimer:Timer!
    
    let socket = WebSocket(url: URL(string: "www://"+kConnectorHost+":"+kConnectorPort+"/")!, protocols: [])
    
    override init() {
        super.init()
        
        socket.delegate = self
        socket.connect()
        connectStatus = -0
        
    }
    
}
// socket delegate
extension SESocketManager {
    func websocketDidConnect(socket: WebSocket) {
        connectStatus = 1
        beatTimer = Timer.scheduledTimer(timeInterval: TimeInterval(heartBeatTimeinterval),
                                         target: self,
                                         selector: #selector(sendBeat),
                                         userInfo: nil,
                                         repeats: true)
        
        print("websocket is connected")
    }
    
    func websocketDidDisconnect(socket: WebSocket, error: NSError?) {
        if let e = error {
            print("websocket is disconnected: \(e.localizedDescription)")
        } else {
            print("websocket disconnected")
        }
    }
    
    func websocketDidReceiveMessage(socket: WebSocket, text: String) {
        print("Received text: \(text)")
    }
    
    func websocketDidReceiveData(socket: WebSocket, data: Data) {
        print("Received data: \(data.count)")
    }
}


extension SESocketManager {
    func sendBeat() {
        
        sendSocketParams(param:["c":"3"])
    }
    
    func sendSocketParams(param: Any) {
        
        let data:Data = NSKeyedArchiver.archivedData(withRootObject: param)
        
        socket.write(data: data) {
            
        }
    }
    
}



