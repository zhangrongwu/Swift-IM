# **swift socket**
####基于CocoaAsyncSocket封装即时通讯模块
####具体问题需根据公司具体业务逻辑进行设计
####主要功能
* 建立连接
* 心跳请求
* 断开重连机制
* 请求重发机制
* 请求超时策略

##### 1.创建长连接
    func creatSocketToConnectServer() -> Void {
        do {
            connectStatus = 0
            try  clientSocket.connect(toHost: kConnectorHost, onPort: UInt16(kConnectorPort), withTimeout: TimeInterval(timeOut))
        } catch {
            print("conncet error")
        }
    }
##### 2.长连接建立后开始与服务器校验登录与发送心跳包
 	  
    func socketDidConnectCreatLogin() -> Void {
        let login = ["c":"1","p":"ca5542d60da951afeb3a8bc5152211a7","d":"dev_"]
        socketWriteDataToServer(param: login)
        reconnectionCount = 0
        connectStatus = 1
        reconncetStatusHandle?(true)
        delegate?.reconnectionSuccess()
        guard let timer = self.reconnectTimer else {
            return
        }
        timer.invalidate()
    }
    
    // 长连接建立后 开始发送心跳包
    func socketDidConnectBeginSendBeat() -> Void {
        beatTimer = Timer.scheduledTimer(timeInterval: TimeInterval(heartBeatTimeinterval),
                                         target: self,
                                         selector: #selector(sendBeat),
                                         userInfo: nil,
                                         repeats: true)
        RunLoop.current.add(beatTimer, forMode: RunLoopMode.commonModes)
    }
    
    // 向服务器发送心跳包
    func sendBeat() {
        let beat = ["c":"3"]
        socketWriteDataToServer(param:beat)
    }
    
##### 3.向服务器发送数据出口
    func socketWriteDataToServer(param: Dictionary<String, Any>) {
        // 1: do   2: try?    3: try!
        guard let data:Data = try? Data(JSONSerialization.data(withJSONObject: param,
                                                               options: JSONSerialization.WritingOptions(rawValue: 1))) else { return }
        clientSocket.write(data, withTimeout: -1, tag: 0)
        clientSocket.readData(to: GCDAsyncSocket.crlfData(), withTimeout: -1, tag: 0)
    }
    
##### 4.断开连接后重新连接操作
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
    
    // 重新连接 在网络状态不佳或者断网情况下把具体情况抛出去处理
    func reconnection() -> Void {
        // 在瞬间切换到后台再切回程序时状态某些时候不改变，
        // 但是未连接，所以添加一个重新连接时先断开连接
        if connectStatus != -1 {
            clientSocket.disconnect()
        }
        // 重新初始化连接
        creatSocketToConnectServer()
    }



##### 5.接收服务器发送到客户端的数据
    func socketDidReadData(data:Data, tag:Int) -> Void {
        guard let json = try? JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions(rawValue: 0)) else {
            return
        }
        print(json)
    }
    
##### 6.GCDAsyncSocketDelegate
    
    extension SESocketManager {
    
    // 与服务器建立连接后根据业务需求发送登录请求、心跳包
    func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) -> Void {
        print("Successful")
        socketDidConnectCreatLogin()
        socketDidConnectBeginSendBeat()
    }
    
    
    // 服务器接收到数据 -->> 接收到数据后抛出去
    func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) -> Void {
        clientSocket.write(data, withTimeout: -1, tag: 0)
        clientSocket.readData(to: GCDAsyncSocket.crlfData(), withTimeout: -1, tag: 0)
        socketDidReadData(data: data, tag: tag)
    }
    
    
    func socket(_ sock: GCDAsyncSocket, didWriteDataWithTag tag: Int) -> Void {
        clientSocket.readData(to: GCDAsyncSocket.crlfData(), withTimeout: -1, tag: 0)
    }
    
    // 断开连接
    func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) -> Void {
        socketDidDisconectBeginSendReconnect()
    }
    }




