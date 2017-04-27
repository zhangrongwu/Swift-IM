//
//  SESocketRequestBaseManager.swift
//  Swift-IM
//
//  Created by zhangrongwu on 2017/2/20.
//  Copyright © 2017年 bocom. All rights reserved.
//  各个模块tcp请求继承该类

import UIKit

typealias SocketSuccessCompletionHandle = (_ object: Any, _ other: Any) ->()
typealias SocketFailureCompletionHandle = (_ error: Any, _ other: Any) ->()

class SESocketRequestBaseManager: NSObject {
    let commManager = SESocketCommManager.instance
    
    
    
    
    // 样例
    func subApp(parameter: Dictionary<String, Any>, success: SocketSuccessCompletionHandle, failure: SocketFailureCompletionHandle) -> Void {
        commManager .request(parameter: parameter,
                             identifier: "",
                             requestApi: "application/subApp",
                             requestType: SocketRequestType.CmdTypeLongDistanceFuncRequest.rawValue,
                             timeOut: 30,
                             resend: true) { (obj, err, oth) in
            
        }
    }
}
