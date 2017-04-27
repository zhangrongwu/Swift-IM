//
//  SESocketManager.swift
//  Swift-IM
//
//  Created by zhangrongwu on 2017/2/20.
//  Copyright © 2017年 bocom. All rights reserved.
//  项目与框架连接模块

import UIKit
import CocoaAsyncSocket
public protocol SocketManagerDelegate  {
    func reconnectionSuccess()
    func didReadData(data: Data, tag: Int)
}

typealias reconnetCompletionHandle = (Bool) ->()

class SESocketManager: NSObject, GCDAsyncSocketDelegate  {
    open var delegate: SocketManagerDelegate?
    var reconncetStatusHandle : reconnetCompletionHandle?  // 为了后续业务上用户主动连接处理
    
    static let instance = SESocketManager()
    
    var connectStatus = 0 //connect status：1 connect，-1  disconnect，0 connecting
    var reconnectionCount = 0
    
    var beatTimer:Timer!
    var reconnectTimer:Timer!
    
    var clientSocket:GCDAsyncSocket!
    
    override init() {
        super.init()
        
        clientSocket = GCDAsyncSocket()
        clientSocket.delegate = self
        clientSocket.delegateQueue = DispatchQueue.main
        creatSocketToConnectServer()
        
    }
    
    /**
     用户主动重新连接（一般业务都有这个需求：断网后用户下拉）
     */
    public func getReconncetHandle(handle: @escaping reconnetCompletionHandle)  {
        self.reconncetStatusHandle = handle
        reconnection()
    }
    
    
}

extension SESocketManager {
    /** 
     创建长连接
     */
    func creatSocketToConnectServer() -> Void {
        do {
            connectStatus = 0
            try  clientSocket.connect(toHost: kConnectorHost, onPort: UInt16(kConnectorPort), withTimeout: TimeInterval(timeOut))
        } catch {
            print("conncet error")
        }
    }
    
    /** 
     长连接建立后 开始与服务器校验登录
     */
    func socketDidConnectCreatLogin() -> Void {
        let login = ["c":"1","p":"ca5542d60da951afeb3a8bc5152211a7","d":"dev_"]
        socketWriteDataToServer(body: login)
        reconnectionCount = 0
        connectStatus = 1
        reconncetStatusHandle?(true)
        delegate?.reconnectionSuccess()
        guard let timer = self.reconnectTimer else {
            return
        }
        timer.invalidate()
    }
    
    /** 
     长连接建立后 开始发送心跳包
     */
    func socketDidConnectBeginSendBeat() -> Void {
        beatTimer = Timer.scheduledTimer(timeInterval: TimeInterval(heartBeatTimeinterval),
                                         target: self,
                                         selector: #selector(sendBeat),
                                         userInfo: nil,
                                         repeats: true)
        RunLoop.current.add(beatTimer, forMode: RunLoopMode.commonModes)

    }
    
    
    /** 
     向服务器发送心跳包
     */
    func sendBeat() {
        let beat = ["c":"3"]
        socketWriteDataToServer(body:beat)
    }
    
    /** 
     向服务器发送数据
     */
    func socketWriteDataToServer(body: Dictionary<String, Any>) {
        // 1: do   2: try?    3: try!
        guard let data:Data = try? Data(JSONSerialization.data(withJSONObject: body,
                                                               options: JSONSerialization.WritingOptions(rawValue: 1))) else {
                                                                return
        }
        print(body)
        clientSocket.write(data, withTimeout: -1, tag: 0)
        clientSocket.readData(to: GCDAsyncSocket.crlfData(), withTimeout: -1, tag: 0)
    }
    
    /** 
     接收到服务器的数据
     */
    func socketDidReadData(data:Data, tag:Int) -> Void {
        delegate?.didReadData(data: data, tag: tag)
    }
    
    /** 
     重新连接操作
     */
    func socketDidDisconectBeginSendReconnect() -> Void {
        
        connectStatus = -1
        
        if reconnectionCount >= 0 && reconnectionCount < beatLimit  {
            reconnectionCount = reconnectionCount + 1
            timerInvalidate(timer: reconnectTimer)
            let time:TimeInterval = pow(2, Double(reconnectionCount))
            
            reconnectTimer = Timer.scheduledTimer(timeInterval: time,
                                                  target: self,
                                                  selector: #selector(reconnection),
                                                  userInfo: nil,
                                                  repeats: true)
            RunLoop.current.add(reconnectTimer, forMode: RunLoopMode.commonModes)
            
        } else {
            reconnectionCount = -1
            reconncetStatusHandle?(false)
            
            timerInvalidate(timer: reconnectTimer)
        }
    }
    
    /**
     重新连接 在网络状态不佳或者断网情况下把具体情况抛出去处理
     */
    func reconnection() -> Void {
       
        /**
         在瞬间切换到后台再切回程序时状态某些时候不改变
         但是未连接，所以添加一个重新连接时先断开连接
         */
        if connectStatus != -1 {
            clientSocket.disconnect()
        }
        
        // 重新初始化连接
        creatSocketToConnectServer()
    }
    
    
    func timerInvalidate(timer: Timer!) -> Void {
        guard let inTimer = timer else {
            return
        }
        inTimer.invalidate()
    }
}









/**
 socket delegate
 */
extension SESocketManager {
    
    /**
     与服务器建立连接后根据业务需求发送登录请求、心跳包
     */
    func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) -> Void {
        print("Successful")
        socketDidConnectCreatLogin()
        socketDidConnectBeginSendBeat()
    }
    
    
    /**
     服务器接收到数据 -->> 接收到数据后抛出去
     */
    func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) -> Void {
        clientSocket.write(data, withTimeout: -1, tag: 0)
        clientSocket.readData(to: GCDAsyncSocket.crlfData(), withTimeout: -1, tag: 0)
        socketDidReadData(data: data, tag: tag)
    }
    
    
    func socket(_ sock: GCDAsyncSocket, didWriteDataWithTag tag: Int) -> Void {
        clientSocket.readData(to: GCDAsyncSocket.crlfData(), withTimeout: -1, tag: 0)
    }
    
    /**
     断开连接
     */
    func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) -> Void {
        socketDidDisconectBeginSendReconnect()
    }
}



