//
//  AudioBuffer.swift
//  IOSExperiments
//
//  Created by 0x384c0 on 26.08.16.
//  Copyright © 2016 0x384c0 . All rights reserved.
//

import Foundation
import ffmpeg


class AudioBuffer {
    static let shared = AudioBuffer()
    fileprivate init(){}
    
    fileprivate var buffer = RingBuffer<Array<UInt8>>(count: 2)
    
    func put(_ frame:AVFrame){
        
        let
        array = bufferPointerToArray(frame.data.0!,count: Int(frame.linesize.0 ))
        
        while !buffer.write(array) {
            usleep(100 * 1000)
        }
    }
    func get() -> UnsafeMutablePointer<UInt8>? {
        if let array = buffer.read(){
            return arrayToBufferPointer(array)
        }
        return nil
    }
    
    
    fileprivate func bufferPointerToArray<T>(_ pointer: UnsafeMutablePointer<T>,count:Int) -> Array<T>{
        let bufferTmp = UnsafeBufferPointer(
            start: pointer,
            count: count
        )
        return Array(bufferTmp)
    }
    fileprivate func arrayToBufferPointer<T>(_ array: Array<T>) -> UnsafeMutablePointer<T>{
        return UnsafeMutablePointer(mutating: array)
    }
}
