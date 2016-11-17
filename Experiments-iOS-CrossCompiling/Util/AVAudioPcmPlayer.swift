//
//  AVAudioPlayer.swift
//  IOSExperiments
//
//  Created by 0x384c0   on 30.08.16.
//  Copyright © 2016 0x384c0 . All rights reserved.
//



import AVFoundation

class AVAudioPcmPlayer{
    // store persistent objects
    var audioEngine:AVAudioEngine
    var player:AVAudioPlayerNode
    var mixer:AVAudioMixerNode
    var format:AVAudioFormat
    var buffer:AVAudioPCMBuffer!
    
    init(){
        // initialize objects
        audioEngine = AVAudioEngine()
        player = AVAudioPlayerNode()
        mixer = audioEngine.mainMixerNode
        //format = player.outputFormatForBus(0)
        format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 44100, channels: 1, interleaved: false)
        
        
    }
    deinit{
        stopPlaying()
    }
    
    func playInt16BitData(_ int16Data:[Int16],completionHandler: AVAudioNodeCompletionHandler? = nil){
        setInt16Buffer(int16Data)
        playFromBuffer(completionHandler)
    }
    //MARK: convert
    fileprivate func setInt16Buffer(_ int16Buffer:[Int16]){
        buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: int16Buffer.count.cast())
        buffer.frameLength = int16Buffer.count.cast()
        for (index, element) in int16Buffer.enumerated() {
            buffer.floatChannelData!.pointee[index] = int16SampleToFloat32(element)
        }
    }
    fileprivate func int16SampleToFloat32(_ int:Int16) -> Float32{
        return int.cast() / Float32(Int16.max)
    }
    //MARK: play
    fileprivate func playFromBuffer(_ completionHandler: AVAudioNodeCompletionHandler?){
        // setup audio engine
        audioEngine.attach(player)
        audioEngine.connect(player, to: mixer, format: format)
        do {
            try audioEngine.start()
        } catch {
            preconditionFailure()
        }
        
        // play player and buffer
        player.play()
        player.scheduleBuffer(buffer, at: nil, options: .interrupts, completionHandler: completionHandler)
    }
    fileprivate func stopPlaying(){
        
        player.stop()
        audioEngine.disconnectNodeInput(player)
        audioEngine.detach(player)
    }
}
extension AVAudioPcmPlayer{
    //MARK: test
    func playSineWave(){
        playInt16BitData(generateSineWave())
    }
    fileprivate func generateSineWave() -> [Int16] {
        var result = [Int16]()
        // generate sine wave
        let sampleRate:Float = Float(
            format.sampleRate
        )
        for i in 0...100 {
            let val = sinf(441.0 * Float(i) * 2 * Float(M_PI)/sampleRate)
            result.append((Int16.max.cast() * val).cast() )
        }
        return result
    }
    
}
