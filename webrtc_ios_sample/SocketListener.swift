//
//  SocketManager.swift
//  webrtc_ios_sample
//
//  Created by justin dongwook Jung on 2020/07/28.
//  Copyright © 2020 justin dongwook Jung. All rights reserved.
//

import Foundation
import SocketIO
import SwiftyJSON
import WebRTC
import Starscream

class SocketListener: NSObject {
    static let shared = SocketListener()
    
    var manager: SocketManager?
    var socket: SocketIOClient!
    var socketId: String!
    var roomId: String!
    var id = 0
    
    override init() {
        super.init()
        
        self.manager = SocketManager(socketURL: URL(string: "https://106.240.247.44:7605")!, config: [.log(false), .forceWebsockets(true), .secure(true), .selfSigned(true)])
        
    }
    
    func establishConnection() {
        
        socket = self.manager?.defaultSocket
        socket = self.manager?.socket(forNamespace: "/SignalServer")
        
        socket.on("knowledgetalk"){data, ack in
            print("receive ::: \(data)")
            let eventOp: String = getValue(inputData: data, key: "eventOp")!
            
            let signalOp: String = getValue(inputData: data, key: "signalOp")!
            if(!eventOp.isEmpty){
                if eventOp == "Register" {
                    self.socketId = getValue(inputData: data, key: "socketId") as! String
                }
                else if eventOp == "RoomJoin" {
                    self.roomId = getValue(inputData: data, key: "roomId") as! String
                }
                else if eventOp == "SDP" {
                    
                }
                
            }
            
            if(!signalOp.isEmpty){
                
            }
            
            
        }
        
        socket.on(clientEvent: .connect){data, ack in
            print("socket connected!")
        }
        
        socket.on(clientEvent: .error){data, ack in
            print("socket error")
        }
        
        socket.on(clientEvent: .disconnect){data, ack in
            print("socket disconnect")
        }
        
        socket.on(clientEvent: .reconnect){data, ack in
            print("socket reconnect")
        }
        
        socket.connect()
                   
    }

    func Register(){
        
        let sample: [String: Any] = [
            "eventOp": "Register",
            "reqNo": getReqNo(),
            "reqDate": getDate()
        ]
        
        let sendData = arrayToJSON(inputData: sample)
        socket.emit("knowledgetalk", sendData as! SocketData)
        
    }
    
    func roomJoin(){
        
        let sample: [String: Any] = [
            "eventOp": "RoomJoin",
            "reqNo": getReqNo(),
            "reqDate": getDate()
        ]
        
        let sendData = arrayToJSON(inputData: sample)
        socket.emit("knowledgetalk", sendData as! SocketData)
    }
    
    func sdpOffer(sdp: String){
        let sample: [String: Any] = [
            "eventOp": "SDP",
            "reqNo": getReqNo(),
            "reqDate": getDate(),
            "roomId": getRoomId(),
            "sdp": sdp,
            "type": "cam"
        ]
        
        let sendData = arrayToJSON(inputData: sample)
        socket.emit("knowledgetalk", sendData as! SocketData)
    }
    
    
    
}

func arrayToJSON(inputData: [String: Any]) -> Any {
    do {
        let jsonData = try JSONSerialization.data(withJSONObject: inputData, options: [])
        let jsonString = String(data: jsonData, encoding: String.Encoding.utf8)!
        let temp = jsonString.data(using: .utf8)!
        let jsonObject = try JSONSerialization.jsonObject(with: temp, options: .allowFragments)
        
        return jsonObject
        
    } catch {
        return 0
    }
}

func getValue(inputData: Any, key: String) -> String? {
    let jsonData = JSON(inputData)[0]
    print(jsonData)
    let result = jsonData[key].stringValue
    if(result.isEmpty){
        return ""
    } else {
        return result
    }
   
}

func getReqNo() -> String {
    var reqNo = ""
    
    for _ in 0..<7 {
        reqNo = reqNo + String(Int.random(in: 0...9))
    }
    
    return reqNo
}

func getDate() -> String {
    let today = Date()
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "ko_KR")
    formatter.dateFormat = "yyyyMMddHHmmss"
    let dateString = formatter.string(from: today)

    return dateString
}
