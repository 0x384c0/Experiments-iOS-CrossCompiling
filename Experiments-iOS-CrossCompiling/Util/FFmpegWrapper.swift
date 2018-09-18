//
//  FFmpegWrapper.swift
//  IOSExperiments
//
//  Created by 0x384c0 on 19.08.16.
//  Copyright © 2016 0x384c0 . All rights reserved.
//

import Foundation
import ffmpeg

class FFmpegWrapper{
    
    fileprivate var
    filePath = "",
    formatContext:UnsafeMutablePointer<AVFormatContext>? = nil,
    videoStreamId = -1,
    videoCodecContext:UnsafeMutablePointer<AVCodecContext>? = nil,
    audioStreamId = -1,
    audioCodecContext:UnsafeMutablePointer<AVCodecContext>? = nil
    var
    width:Int32 = 0,
    height:Int32 = 0,
    framePerSecond = 25
    
    func registerAll(){
        av_register_all()
    }
    func unregisterAll(){
        // Close the codec
        avcodec_close(videoCodecContext)
        // Close the video file
        avformat_close_input(&formatContext)
        avformat_free_context(formatContext)
    }
    
    func readFile(_ filePath:String){
        self.filePath = filePath
        //open
        if avformat_open_input(&formatContext, filePath, nil, nil) != 0 {
            preconditionFailure("Couldn't open file")
        }
    }
    func dumpCodecs(){
        //find meta
        if avformat_find_stream_info(formatContext, nil) < 0 {
            preconditionFailure("Couldn't find stream information")
        }
        //dump meta
        av_dump_format(formatContext, 0, filePath, 0)
    }
    func findVideoCodecsInFFmpeg(){
        //find codec
        videoStreamId = findStreamId(forType: AVMEDIA_TYPE_VIDEO, formatContext: formatContext!.pointee)
        
        videoCodecContext = formatContext!.pointee.streams[videoStreamId]!.pointee.codec
        let
        codec = avcodec_find_decoder(videoCodecContext!.pointee.codec_id)
        if codec == nil {
            preconditionFailure("Unsupported codec")
        }
        if avcodec_open2(videoCodecContext, codec, nil) < 0 {
            preconditionFailure("Could not open codec")
        }
        
        width = videoCodecContext!.pointee.width
        height = videoCodecContext!.pointee.height
    }
    func enumerateVideoFrames(_ framePerSecond:Int = 25,scaleBy:Float,frameHandler: @escaping (AVFrame) -> (),completion: @escaping () -> ()){
        self.framePerSecond = framePerSecond
        DispatchQueue.global(qos: .default).async {[unowned self] in
            var
            frame = av_frame_alloc(),
            scaler = AVFrameScaler(width: self.width, height: self.height, codecContextPixFmt: self.videoCodecContext!.pointee.pix_fmt)
            
            //scale image
            let packet = UnsafeMutablePointer<AVPacket>.allocate(capacity: 1)
            while av_read_frame(self.formatContext, packet) >= 0 {
                if packet.pointee.stream_index == Int32(self.videoStreamId) {
                    // Video stream packet
                    if self.decodeVideo(self.videoCodecContext!, frame: frame!, packet: packet) {
                        let convertedFrame = scaler.scale(frame!, scaleBy: scaleBy)
                        self.putAndLogFrame(convertedFrame,frameHandler: frameHandler)
                        usleep(UInt32((1000/framePerSecond) * 1000))
                    }
                }
                av_packet_unref(packet)
            }
            av_frame_free(&frame)
            scaler.freeConvertedFrame()
            DispatchQueue.main.async {
                completion()
            }
        }
    }
    
    
    
    fileprivate func findStreamId(forType mediaType:AVMediaType,formatContext:AVFormatContext) -> Int{
        //get videstream number
        for i in 0..<Int(formatContext.nb_streams) {
            let stream = formatContext.streams[i]
            if stream!.pointee.codec.pointee.codec_type == mediaType {
                if stream == nil {
                    preconditionFailure("Didn't find a stream for type \(mediaType.rawValue)")
                }
                return i
            }
        }
        return -1
    }
    fileprivate func decodeVideo(
        _ codecContext: UnsafeMutablePointer<AVCodecContext>,
        frame: UnsafeMutablePointer<AVFrame>,
        packet: UnsafeMutablePointer<AVPacket>
        ) -> Bool {
        /**
         映像をデコードする
         */
        
        let finished = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
        avcodec_decode_video2(codecContext, frame, finished, packet)
        return finished.pointee != 0
        
        
//        avcodec_send_packet(codecContext, packet)
//        let finished = avcodec_receive_frame(codecContext, frame)
//        return finished != 0
    }
    fileprivate func putAndLogFrame(_ frame:UnsafeMutablePointer<AVFrame>, frameHandler: @escaping (AVFrame) -> ()){
        logVideoFrame(frame)
        DispatchQueue.main.async {
            frameHandler(frame.pointee)
        }
    }
    let VERBOSE_FRAME_LOGGING = true
    func logVideoFrame(_ frame:UnsafeMutablePointer<AVFrame>){
        #if VERBOSE_FRAME_LOGGING
            print("---------- frame 0 channel \(Date()) \n")
            let data = UnsafeMutablePointer<Int8>(OpaquePointer( frame.pointee.data.0))
            let linesize = Int((frame.pointee.linesize.0 ) / 2)
            let buffer = UnsafeBufferPointer(
                start: data,
                count: linesize
            )
            for i in 0..<linesize{
                print(buffer[i],terminator:" ")
            }
            print("\n")
        #else
            print("----------")
            print("channel 0: \(frame.pointee.data.0?.pointee )     linesize: \(frame.pointee.linesize.0 )")
            print("channel 1: \(frame.pointee.data.1?.pointee )     linesize: \(frame.pointee.linesize.1 )")
            print("channel 2: \(frame.pointee.data.2?.pointee )     linesize: \(frame.pointee.linesize.2 )")
            print("channel 3: \(frame.pointee.data.3?.pointee )     linesize: \(frame.pointee.linesize.3 )")
            print("channel 4: \(frame.pointee.data.4?.pointee )     linesize: \(frame.pointee.linesize.4 )")
            print("channel 5: \(frame.pointee.data.5?.pointee )     linesize: \(frame.pointee.linesize.5 )")
            print("channel 6: \(frame.pointee.data.6?.pointee )     linesize: \(frame.pointee.linesize.6 )")
            print("channel 7: \(frame.pointee.data.7?.pointee )     linesize: \(frame.pointee.linesize.7 )")
        #endif
    }
}
//MARK: AUDIO
extension FFmpegWrapper{
    func getAudioCodecContext() -> AVCodecContext{
        return audioCodecContext!.pointee
    }
    func enumerateAudioFrames(_ frameHandler: @escaping (AVFrame) -> (),completion: @escaping () -> ()){
        self.framePerSecond = 25
        DispatchQueue.global(qos: .default).async {[unowned self] in
            var
            frame = av_frame_alloc(),
            packet = UnsafeMutablePointer<AVPacket>.allocate(capacity: 1)
            
            while av_read_frame(self.formatContext, packet) >= 0 {
                if packet.pointee.stream_index == self.audioStreamId.cast() {
                    
                    if self.decodeAudio4(self.audioCodecContext!, frame: frame!, packet: packet) {
                        self.logAudioFrame(frame!)
                        frameHandler(frame!.pointee)
                    }
                }
                av_packet_unref(packet)
            }
            av_frame_free(&frame)
            DispatchQueue.main.async {
                completion()
            }
        }
    }
    func findAudioCodecsInFFmpeg(){
        //find codec
        audioStreamId = findStreamId(forType: AVMEDIA_TYPE_AUDIO, formatContext: formatContext!.pointee)
        audioCodecContext = formatContext!.pointee.streams[audioStreamId]!.pointee.codec
        let
        codec = avcodec_find_decoder(audioCodecContext!.pointee.codec_id)
        if codec == nil {
            preconditionFailure("Unsupported codec")
        }
        if avcodec_open2(audioCodecContext, codec, nil) < 0 {
            preconditionFailure("Could not open codec")
        }
        print(audioCodecContext!.pointee)
    }
    fileprivate func decodeAudio4(
        _ codecContext: UnsafeMutablePointer<AVCodecContext>,
        frame: UnsafeMutablePointer<AVFrame>,
        packet: UnsafeMutablePointer<AVPacket>
        ) -> Bool {
        /**
         映像をデコードする
         */
        let finished = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
        avcodec_decode_audio4(codecContext, frame, finished, packet)
        return finished.pointee != 0
    }
    
    func logAudioFrame(_ frame:UnsafeMutablePointer<AVFrame>){
        #if VERBOSE_FRAME_LOGGING
            print("---------- pcm s16le \(Date()) \n")
            let data = UnsafeMutablePointer<Int8>(OpaquePointer( frame.pointee.data.0))
            let linesize = Int((frame.pointee.linesize.0 ) / 2)
            let buffer = UnsafeBufferPointer(
                start: data,
                count: linesize
            )
            for i in 0..<linesize{
                print(buffer[i],terminator:" ")
            }
            print("\n")
        #else
            let
            frame = frame.pointee,
            pixFmt = String.fromCString(av_get_sample_fmt_name(AVSampleFormat(frame.format)), length: 5) ?? "nil"
            
            print("format: \(pixFmt)   channel_0: \(frame.data.0 )   linesize: \(frame.linesize.0 )   sample_rate: \(frame.sample_rate)   samplesPerCahnnel: \(frame.nb_samples)   pts: \(frame.pts)")
        #endif
    }
}
