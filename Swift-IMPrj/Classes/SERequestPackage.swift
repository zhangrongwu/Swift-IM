//
//  SERequestPackage.swift
//  Swift-IM
//
//  Created by zhangrongwu on 2017/3/3.
//  Copyright © 2017年 bocom. All rights reserved.
//  请求参数包

import UIKit

class SERequestPackage: NSObject {
   
    var body: Dictionary<String, Any> = [:]
    var identifier: String = ""
    var timeOut: TimeInterval = 30
    var resend: Bool = false
    var requestApi: String = ""
    
    var requestType: SocketRequestType = .CmdTypeLocFuncRequest
    
}
