//
//  AVFrameScaler.swift
//  IOSExperiments
//
//  Created by 0x384c0 on 30.08.16.
//  Copyright © 2016 0x384c0 . All rights reserved.
//

import ffmpeg


class AVFrameScaler {
    var
    convertedFrame:UnsafeMutablePointer<AVFrame>?,
    dst_format:AVPixelFormat,
    size:Int32,
    width:Int32,
    height:Int32,
    buffer:[UInt8],
    src_format:AVPixelFormat
    
    init(width:Int32,height:Int32,codecContextPixFmt:AVPixelFormat){
        self.width = width
        self.height = height
        src_format = codecContextPixFmt
        dst_format = AV_PIX_FMT_YUV420P
        
        
        convertedFrame = av_frame_alloc()
        convertedFrame?.pointee.width = width
        convertedFrame?.pointee.height = height
        convertedFrame?.pointee.format = dst_format.rawValue
        
        
        size = av_image_get_buffer_size(dst_format, width, height, 1)
        
        // Assign a buffer to the frame or you will get "bad dst image pointers"
        buffer = [UInt8](repeating: 0, count: Int(size))
        
        av_image_fill_arrays(
            &(convertedFrame!.pointee.data.0),
            &(convertedFrame!.pointee.linesize.0),
            buffer,
            dst_format,
            width,
            height,
            1
        )
    }
    
    func scale(_ frame:UnsafePointer<AVFrame>,scaleBy:Float) -> UnsafeMutablePointer<AVFrame>{
        let swsContextOption = sws_getContext(
            self.width,
            self.height,
            self.src_format,
            Int32(Float(self.width)   * scaleBy),
            Int32(Float(self.height)  * scaleBy),
            dst_format,
            SWS_BILINEAR,
            nil, nil, nil)
        
        _ = self.swsScale(swsContextOption!, source: frame, target: convertedFrame!, height: self.height)
        return convertedFrame!
    }
    
    func freeConvertedFrame(){
        av_frame_free(&convertedFrame)
    }
    
    
    /**
     sws_scaleを実行する
     
     :param: option SwsContextの設定を入力したSwsContextOptionインスタンス
     :param: source 変換前のフレーム
     :param: target 変換後のフレーム: バッファーを持っていなければならない！
     :returns:
     */
    fileprivate func swsScale(_ option: OpaquePointer, source: UnsafePointer<AVFrame>, target: UnsafePointer<AVFrame>, height: Int32) -> Int {
        
        let sourceData = [
            UnsafePointer<UInt8>(source.pointee.data.0),
            UnsafePointer<UInt8>(source.pointee.data.1),
            UnsafePointer<UInt8>(source.pointee.data.2),
            UnsafePointer<UInt8>(source.pointee.data.3),
            UnsafePointer<UInt8>(source.pointee.data.4),
            UnsafePointer<UInt8>(source.pointee.data.5),
            UnsafePointer<UInt8>(source.pointee.data.6),
            UnsafePointer<UInt8>(source.pointee.data.7),
            ]
        let sourceLineSize = [
            source.pointee.linesize.0,
            source.pointee.linesize.1,
            source.pointee.linesize.2,
            source.pointee.linesize.3,
            source.pointee.linesize.4,
            source.pointee.linesize.5,
            source.pointee.linesize.6,
            source.pointee.linesize.7
        ]
        
        let targetData = [
            target.pointee.data.0,
            target.pointee.data.1,
            target.pointee.data.2,
            target.pointee.data.3,
            target.pointee.data.4,
            target.pointee.data.5,
            target.pointee.data.6,
            target.pointee.data.7
        ]
        let targetLineSize = [
            target.pointee.linesize.0,
            target.pointee.linesize.1,
            target.pointee.linesize.2,
            target.pointee.linesize.3,
            target.pointee.linesize.4,
            target.pointee.linesize.5,
            target.pointee.linesize.6,
            target.pointee.linesize.7
        ]
        let result = sws_scale(
            option,
            sourceData,
            sourceLineSize,
            0,
            height,
            targetData,
            targetLineSize
        )
        return Int(result)
    }
    
}
