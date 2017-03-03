//
//  SNScoketConfig.swift
//  Swift-IM
//
//  Created by zhangrongwu on 2017/2/20.
//  Copyright © 2017年 bocom. All rights reserved.
//

import Foundation
let heartBeatTimeinterval = 40
let kMaxReconnection_time = 6
let beatLimit = 10
let timeOut = 10


let kConnectorHost = "183.196.130.125"
let kConnectorPort = "6101"


enum SocketRequestType:Int {
    case CmdType_None = 0 // 未登录
    case CmdType_ConnectRequest = 1 // 连接请求
    case CmdType_ConnectSuccessBack = 2 // 连接请求 正确 回调
    case CmdType_HeartBeatRequest   = 3 // 心跳请求
    case CmdType_HeartBeatSuccessBack     = 4 // 心跳请求 正确 回调
    case CmdType_LocFuncRequest   = 5  //功能本地调用(相对于 7)
    case CmdType_LocFuncSuccessBack      = 6 // 功能本地调用 正确 回调
    case CmdType_LongDistanceFuncRequest  = 7 // 功能远程调用
    case CmdType_LongDistanceFuncBack = 8 // 功能远程调用 正确 回调
    case CmdType_EnterBackgroundRequest   = 9 // APP切到后台
    case CmdType_Notify       = 10 // 消息更新提示
    case CmdType_Message      = 11 // 推送更新内容
    case CmdType_SystemActionRequest = 12 // 系统操作消息
    case CmdType_ActionBack   = 13 // 系统操作确认
}
