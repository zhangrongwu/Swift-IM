//
//  SESocketManager.swift
//  Swift-IM
//
//  Created by zhangrongwu on 2017/2/20.
//  Copyright © 2017年 bocom. All rights reserved.
//  项目与框架连接模块

import UIKit
import Alamofire
import SocketIO

class SESocketManager: NSObject {
    
    static let instance = SESocketManager()
    
    var connectStatus = 0 //connect status：1 connect，-1 not connect，0 connecting
    
    var  beatTimer:Timer!
    
    let socket = SocketIOClient(socketURL: URL(string: kConnectorHost+":"+kConnectorPort)!, config: [.log(true), .forcePolling(true)])
    
    
    override init() {
        super.init()
        
        socket.connect()
        connectStatus = -0
      
        socket.connect(timeoutAfter: timeOut) {
            print("reconnect")
            self.socket.reconnect()
        }
        
        socket.reconnects = true
        socket.reconnectWait = 5
        
        
        self.socket.on("currentAmount")  {data, ack in
            print(" --- socket connected")
        }
        
    }
    
}
// socket delegate
extension SESocketManager {
   
}


extension SESocketManager {
    func sendBeat() {
        
        sendSocketParams(param:["c":"3"])
    }
    
    func sendSocketParams(param: Any) {
        let data:Data = NSKeyedArchiver.archivedData(withRootObject: param)
        self.socket.on("currentAmount")  {data, ack in
            print("socket connected")
        }
        self.socket.emitWithAck("sock", data)
        
//        socket.write(data: data) {
        
//        }
    }
    
}



