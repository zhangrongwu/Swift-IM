//
//  SESocketCommManager.swift
//  Swift-IM
//
//  Created by zhangrongwu on 2017/2/20.
//  Copyright © 2017年 bocom. All rights reserved.
//  所有tcp请求入口、出口 <数据处理、断开连接后重新发送数据>

import UIKit
import SwiftyJSON
import Foundation

typealias SocketWriteDataCompletionHandle = (_ object: Any, _ error: Any, _ other: Any) ->()

class SESocketCommManager: NSObject, SocketManagerDelegate {
    let socketManager = SESocketManager.instance
    
    var writeDataCompletionHandle: SocketWriteDataCompletionHandle?
    
    static let instance = SESocketCommManager()
    
    var requestsMap: [String: Any] = [:]
    var requestsList: [SERequestPackage] = []
    
    override init() {
        super.init()
        socketManager.delegate = self
        
    }
    
    public func request(parameter: Dictionary<String, Any>,
                        identifier: String,
                        requestApi: String,
                        requestType: Int,
                        timeOut: TimeInterval,
                        resend: Bool,
                        handle: @escaping SocketWriteDataCompletionHandle) -> Void {
        
        var identifier = identifier
        if identifier.isEmpty {
            identifier = creatRequestIdentifier()
        }
        
        let body = packageRequest(parameter: parameter, requestApi: requestApi, requestType: requestType)
        
        DispatchQueue.main.async {
            self.requestsMap.updateValue(handle, forKey: identifier)
            self.registerRequestTimeout(identifier: identifier, timeOut: timeOut)
            
            let package = SERequestPackage()
            package.body = body
            package.identifier = identifier
            package.timeOut = timeOut
            package.resend = resend
            package.requestApi = requestApi
            
            self.requestsList.append(package)
        }
        
        DispatchQueue.global().async {
            self.socketManager.socketWriteDataToServer(body: self.appendIdentifier(body: body, identifier: identifier))
        }
    }
    
    /**
     对参数进行封包
     */
    private func packageRequest(parameter: Dictionary<String, Any>, requestApi: String, requestType: Int) -> Dictionary<String, Any> {
        
        var dict: Dictionary<String, Any> = [:]
        dict.updateValue("\(requestType)", forKey: "c")
        dict.updateValue(requestApi, forKey: "p")
        dict.updateValue(parameter, forKey: "d")
        return dict
    }
    
    
    /**
     创建唯一标识
     */
    private  func creatRequestIdentifier() -> String {
        let requestIdentifier = arc4random() % 100000
        return "\(requestIdentifier)"
    }
    
    /**
     超时操作
     */
    private  func registerRequestTimeout(identifier: String, timeOut: TimeInterval) -> Void {
        guard timeOut > 0 else {
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + timeOut) {
            
            guard let handle:SocketWriteDataCompletionHandle = self.requestsMap[identifier] as? SocketWriteDataCompletionHandle else {
                return
            }

            handle("请求超时", "",identifier)
            self.removeRequestHandel(identifier: identifier)
        }
    }
    
    /**
     请求唯一标示拼接到对应参数中，根据具体协议具体实现
     */
    func appendIdentifier(body: Dictionary<String, Any>, identifier: String) -> Dictionary<String, Any> {
        
        let path: String = body["p"] as! String
        let identifierPath: String = path + "#" + identifier
        
        var identifierBody : Dictionary<String, Any> = body
        identifierBody.updateValue(identifierPath, forKey: "p")
        
        return identifierBody
    }
    
    /**
     请求成功后移除requestMap中的block回调
     */
    func removeRequestHandel(identifier: String) -> Void {
        self.requestsMap.removeValue(forKey: identifier)
        if self.requestsMap.count == 0 {
            var index = 0
            for value:SERequestPackage in self.requestsList {
                if value.identifier == identifier {
                    self.requestsList.remove(at: index)
                }
                index += 1
            }
        }
    }
}


/**
 delegate
 */
extension SESocketCommManager {
    
    /**
     重连成功 请求队列重新处理
     */
    func reconnectionSuccess() {
        for package:SERequestPackage in self.requestsList {
            if self.requestsMap.keys.contains(package.identifier) {
                self.socketManager.socketWriteDataToServer(body: self.appendIdentifier(body: package.body, identifier: package.identifier))
            }
        }
    }
    
    /**
     接收数据 <自定义协议逻辑>
     */
    func didReadData(data: Data, tag: Int) {
        
        let json = JSON(data: data)
        
        /**
         与服务器协定的唯一标识
         接收消息命令
         接收到的数据内容
         */
        let p = json["p"].string
        let c = json["c"].intValue
        let object = json["d"]
        
        if c == SocketRequestType.CmdTypeLocFuncSuccessBack.rawValue || c == SocketRequestType.CmdTypeLongDistanceFuncBack.rawValue {
            /**
             正常请求回调
             */
            let handelIdentifier = p?.components(separatedBy: "#")
            let identifier = handelIdentifier?.last
            guard let handle:SocketWriteDataCompletionHandle = self.requestsMap[identifier!] as? SocketWriteDataCompletionHandle else {
                return
            }
            /**
             回调处理
             */
            handle(object, c, identifier!)
            self.removeRequestHandel(identifier: identifier!)
            
        } else {
            if c != SocketRequestType.CmdTypeHeartBeatSuccessBack.rawValue {
                /**
                 未登录状态
                 */
                if c == SocketRequestType.CmdTypeNone.rawValue {
                    
                } else {
                    if !object.isEmpty {
                        let userInfo:Dictionary<String, Any> = ["command":json["c"]]
                        /**
                         接收到服务器主动推送消息 把对应的消息分发出去
                         */
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "NotificationReceiveMessage"), object: object, userInfo: userInfo)
                    }
                }
            }
        }
    }
}



