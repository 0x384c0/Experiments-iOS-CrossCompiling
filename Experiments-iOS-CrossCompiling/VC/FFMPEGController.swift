//
//  FFMPEGController.swift
//  IOSExperiments
//
//  Created by 0x384c0 on 16.08.16.
//  Copyright © 2016 0x384c0. All rights reserved.
//

import Foundation
import SDL
import Charts
import ffmpeg
import TheAmazingAudioEngine

class FFMPEGController: UIViewController {
    
    //MARK: UI
    @IBOutlet weak var vidBtn: UIButton!
    @IBOutlet weak var audioBtn: UIButton!
    @IBOutlet weak var ppmBtn: UIButton!
    @IBOutlet weak var avAudioBtn: UIButton!
    
    @IBOutlet weak var chartView: LineChartView!
    
    @IBAction func buttonTap(_ sender: UIButton) {
        enableButtons(false)
        loadVideoToSDL()
    }
    @IBAction func audioSDLTap(_ sender: AnyObject) {
        enableButtons(false)
        loadAudioToSDL()
    }
    @IBAction func audioAVTap(_ sender: AnyObject) {
        enableButtons(false)
        loadAudioToAVPlayer()
    }
    @IBAction func convertToPPMTap(_ sender: AnyObject) {
//        VideoToPPM().convert(getVideoPath())
    }
    @IBAction func testFftwTap(_ sender: AnyObject) {
        fillChartWithSine()
    }
    @IBAction func micToSpectrum(_ sender: AnyObject) {
        micDataToSpectrum()
    }
    //UI
    fileprivate func enableButtons(_ enable:Bool = true){
        vidBtn.isEnabled = enable
        audioBtn.isEnabled = enable
        ppmBtn.isEnabled = enable
        avAudioBtn.isEnabled = enable
    }
    //lifecycle
    override func viewDidLoad() {
        setupChart()
        setupAEAudioController()
    }
    override func viewDidAppear(_ animated: Bool) {
        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.updateChart), userInfo: nil, repeats: true)//TODO: init selector in constructor
        RunLoop.main.add(self.timer!, forMode: RunLoop.Mode.common)
    }
    override func viewDidDisappear(_ animated: Bool) {
        timer?.invalidate()
    }
    var timer:Timer?
    
    //MARK: players
    fileprivate let
    sdl = SDLWrapper(),
    ffmpeg = FFmpegWrapper(),
    fftw = FftwWrapper()
    fileprivate var
    avPlayer:AVAudioPcmPlayer?
    fileprivate func loadVideoToSDL(){
        sdl.initSdl()
        
        sdl.createWindow(Int32(UIScreen.main.bounds.width), imageHeigh: Int32(UIScreen.main.bounds.height))
        
        ffmpeg.registerAll()
        //ffmpeg.readFile("http://devimages.apple.com/iphone/samples/bipbop/bipbopall.m3u8")
        ffmpeg.readFile(getVideoPath())
        ffmpeg.dumpCodecs()
        ffmpeg.findVideoCodecsInFFmpeg()
        ffmpeg.enumerateVideoFrames(
            scaleBy: Float(UIScreen.main.bounds.width) / Float(ffmpeg.width),
            frameHandler:{[unowned self] frame in
                self.sdl.putFrameInToWindow(frame)
            },
            completion: {[unowned self]  in
                self.ffmpeg.unregisterAll()
                self.sdl.destroyWindow()
                
                self.enableButtons()
            }
        )
    }
    fileprivate func loadAudioToSDL(){
        
        sdl.initSdl()
        
        ffmpeg.registerAll()
        ffmpeg.readFile(getSineWaveAuidioPath())
        ffmpeg.dumpCodecs()
        ffmpeg.findAudioCodecsInFFmpeg()
        sdl.starPlayingFromBuffer(ffmpeg.getAudioCodecContext())
        ffmpeg.enumerateAudioFrames({[unowned self] frame in
            AudioBuffer.shared.put(frame)
            self.fullChartWithAvFrame(frame)
        }) {
            self.ffmpeg.unregisterAll()
            self.sdl.stopPlayingFromBuffer()
            
            self.enableButtons()
        }
    }
    fileprivate func loadAudioToAVPlayer(){
        if avPlayer == nil {
            let player = AVAudioPcmPlayer()
            var int16Buffer = [Int16]()
            
            ffmpeg.registerAll()
            ffmpeg.readFile(getSineWaveAuidioPath())
            ffmpeg.dumpCodecs()
            ffmpeg.findAudioCodecsInFFmpeg()
            ffmpeg.enumerateAudioFrames({frame in
                
                self.fullChartWithAvFrame(frame)
                let data = UnsafeMutablePointer<Int16>(OpaquePointer(frame.data.0))
                
                //(frame.data.0)
                let linesize = Int((frame.linesize.0 ) / 2)
                let buffer = UnsafeBufferPointer(
                    start: data,
                    count: linesize
                )
                int16Buffer.append(contentsOf: Array(buffer))
                
            }) {[unowned self, unowned player] in
                self.ffmpeg.unregisterAll()
                player.playInt16BitData(int16Buffer){[unowned self] in
                    self.avPlayer = nil
                }
                self.enableButtons()
            }
            
            
            avPlayer = player
        } else {
            avPlayer = nil
        }
    }
    
    //MARK: helpers
    fileprivate func getVideoPath() -> String{
        
        let
        filePath = Bundle.main.path(forResource: "small", ofType: "mp4")
        print("OPENING FILE")
        print(filePath)
        return filePath!
    }
    fileprivate func getSineWaveAuidioPath() -> String{
        
        let
        filePath = Bundle.main.path(forResource: "randSine_pcm_s16le_44100", ofType: "wav")
        print("OPENING FILE")
        print(filePath)
        return filePath!
    }
    
    
    //MARK: chart fftw
    let
    max_value = 1.0,//max sample value
    sample_rate = 44100.0,//samples per second
    window_size = 1024//samples per window
    fileprivate var spectrumData:[Double]?
    
    fileprivate func setupChart()  {
        chartView.chartDescription?.text    = ""
        chartView.xAxis.labelPosition       = .bottom
        chartView.xAxis.axisMinimum         = -2
        chartView.xAxis.valueFormatter      = HzValueFormatter(sample_rate: sample_rate)
//        chartView.xAxis.spaceBetweenLabels  = 0
        
        
        chartView.leftAxis.enabled          = false
        chartView.leftAxis.axisMaximum     = max_value
        chartView.leftAxis.axisMinimum     = -max_value * 0.1
        chartView.rightAxis.axisMaximum    = max_value
        chartView.rightAxis.axisMinimum    = -max_value * 0.1
        //chartView.leftAxis.enabled = false
        chartView.rightAxis.maxWidth = 30
        chartView.rightAxis.minWidth = 30
        chartView.rightAxis.drawTopYLabelEntryEnabled = true
    }
    
    func fillChartWithSine(){
        fftw.SAMLE_RATE = sample_rate
        let window:[Double] = generateSine(window_size, SAMLE_RATE: fftw.SAMLE_RATE, MAX_AMPLITUDE: max_value)
        
        let data = fftw.getPowerSpectrum(from: window)
        spectrumData = data
        
    }
    func fullChartWithAvFrame(_ frame:AVFrame){
        let data = UnsafeMutablePointer<Int16>(OpaquePointer(frame.data.0))
        let linesize = Int((frame.linesize.0 ) / 2)
        let buffer = Array(UnsafeBufferPointer(
            start: data,
            count: linesize
            ))
        let buffer1024 = Array(buffer[0 ..< buffer.count/2])
        
        
        spectrumData = fftw.getPowerSpectrum(from: buffer1024)
    }
    
    @objc func updateChart(){
        setChartData(spectrumData)
    }
    fileprivate func setChartData(_ data:[Double]?){
        if let data = data{
            var
            dataEntries = [ChartDataEntry]()
            for (i,value) in data.enumerated() {
                dataEntries.append(ChartDataEntry(x: Double(i), y: value))
            }
            
            
            
            let
            chartDataSet = LineChartDataSet(values: dataEntries, label: "Power spectrum")
            chartDataSet.drawCirclesEnabled = false
            chartDataSet.drawValuesEnabled = false
            chartDataSet.setColor(UIColor.red)
            
            
            chartView.xAxis.axisMaximum = data.count.cast() + Double(2)
            chartView.data = LineChartData(dataSet: chartDataSet)
        }
    }
    fileprivate func generateXVals(_ maxValue:Int) -> [String]{
        var
        xVals = [String]()
        for i in 0..<maxValue {
            xVals.append("\(Int((i.cast() * sample_rate)/maxValue.cast())) Hz: ")
        }
        return xVals
    }
    fileprivate func generateSine(_ windowSize:Int, SAMLE_RATE:Double, MAX_AMPLITUDE:Double) -> [Double]{
        /* Generate two sine waves of different frequencies.
         */
        var result = [Double]()
        for i in 0...(windowSize-1) {
            
            let
            freq1 = sample_rate/2 * 0.3,//Hz
            freq2 = sample_rate/2 * 0.7,//Hz
            
            freq:Double = i < windowSize/3 ? freq1 : freq2
            result.append( sin(Double(i) * M_PI * (freq * 2)/SAMLE_RATE) * MAX_AMPLITUDE)
        }
        return result
    }

    
    //MARK: microphone
    fileprivate var
    controller:AEAudioController?,
    receiver = AEBlockAudioReceiver()
    fileprivate func setupAEAudioController(){
        //create audio controller
        let description = AudioStreamBasicDescription(
            mSampleRate: sample_rate,
            mFormatID: kAudioFormatLinearPCM,
            mFormatFlags:  kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked | kAudioFormatFlagsNativeEndian | kAudioFormatFlagIsNonInterleaved,
            mBytesPerPacket: MemoryLayout<Int16>.size.cast(),
            mFramesPerPacket: 1,
            mBytesPerFrame: MemoryLayout<Int16>.size.cast(),
            mChannelsPerFrame: 1,
            mBitsPerChannel: 8 * MemoryLayout<Int16>.size.cast(),
            mReserved: MemoryLayout<Int16>.size.cast()
        )
        controller = AEAudioController(audioDescription: description, inputEnabled: true)
        controller?.stop()
        
        //create input receiver
        receiver = AEBlockAudioReceiver(){[unowned self] source, time, samples, audio in
            let
            pointerInt16 = UnsafeMutablePointer<Int16>(OpaquePointer(audio!.pointee.mBuffers.mData)),
            bufferPointer = UnsafeBufferPointer(
                start: pointerInt16,
                count: Int(samples)// cast to int to avoid Error: Cannot convert value of type 'UnsafePointer<Double>' to expected argument type 'UnsafePointer<_>'
            ),
            buffer = Array(bufferPointer)
            self.spectrumData = self.fftw.getPowerSpectrum(from: buffer)
        }
    }
    fileprivate func micDataToSpectrum(){
        if !(controller?.running ?? false){
            enableButtons(false)
            controller?.addInputReceiver(receiver)
            do {
                try controller?.start()
            } catch {
                preconditionFailure()
            }
        } else {
            controller?.removeInputReceiver(receiver)
            controller?.stop()
            enableButtons(true)
        }
    }
    deinit{
        if (controller?.running ?? false) {
            controller?.removeInputReceiver(receiver)
        }
        controller?.stop()
    }
}

class HzValueFormatter : NSObject, IAxisValueFormatter{
    var
    sample_rate = 0.0
    init(sample_rate:Double) {
        self.sample_rate = sample_rate
    }
    
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        return "\(Int((value * sample_rate)/axis!.axisMaximum)) Hz: "
    }
}
