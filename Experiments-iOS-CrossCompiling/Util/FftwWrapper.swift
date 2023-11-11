//
//  FftwWrapper.swift
//  IOSExperiments
//
//  Created by 0x384c0 on 06.09.16.
//  Copyright © 2016 0x384c0. All rights reserved.
//

import fftw3
import Foundation

class FftwWrapper {
    var
    SAMLE_RATE = 44100.0,// for logging
    debugLog = false
    fileprivate let
    maxDoubleSampleValue = 1.0
    
    func getPowerSpectrum(from window:[Double]) -> [Double] {
        let
        WINDOW_SIZE = window.count
        let
        ina = realToComplex(window),
        outa = UnsafeMutablePointer<fftw_complex>(OpaquePointer( fftw_malloc(MemoryLayout<fftw_complex>.size * WINDOW_SIZE)))
        
        if debugLog{
            print("\n------- IN -------")
            prinFftwComplex(ina,samplesCount: WINDOW_SIZE)
        }
        
        let p = fftw_plan_dft_1d(WINDOW_SIZE.cast(), ina, outa, FFTW_FORWARD, FFTW_ESTIMATE)
        fftw_execute(p); /* repeat as needed */
        
        if debugLog{
            print("------- OUT real ----------")
            printPowerSpectrum(outa!, WINDOW_SIZE: WINDOW_SIZE, MAX_AMPLITUDE: maxDoubleSampleValue)
        }
        let
        resultTmp = complexToReal(outa!,itemsCount: WINDOW_SIZE),
        result = Array(resultTmp[0..<resultTmp.count/2])
        
        fftw_destroy_plan(p)
        fftw_free(ina)//incorrect checksum for freed object - object was probably modified after being freed.
        fftw_free(outa)//pointer being freed was not allocated
        
        return result
    }
    
    fileprivate func realToComplex(_ window:[Double]) -> UnsafeMutablePointer<fftw_complex>{
        let result = UnsafeMutablePointer<fftw_complex>(OpaquePointer(fftw_malloc(MemoryLayout<fftw_complex>.size * window.count)))
        for (i,value) in window.enumerated() {
            
            if value > maxDoubleSampleValue {
                preconditionFailure("sample value:Double must be lower than \(maxDoubleSampleValue)")
            }
            
            result!.advanced(by: i).pointee.0 = value
            result!.advanced(by: i).pointee.1 = 0
        }
        return result!
    }
    fileprivate func complexToReal(_ ina:UnsafeMutablePointer<fftw_complex>,itemsCount:Int) -> [Double]{
        var result = [Double]()
        for i in 0 ..< itemsCount {
            let
            m1 = ina.advanced(by: i).pointee.0 * ina.advanced(by: i).pointee.0,//  / 2,//
            m2 = ina.advanced(by: i).pointee.0 * ina.advanced(by: i).pointee.0,
            mag =  sqrt(m1 + m2) / (itemsCount.cast() / 2)
            result.append(mag)
        }
        return result
    }
}
//Int 16
extension FftwWrapper {
    func getPowerSpectrum(from window:[Int16]) -> [Double]{
        let int16Window = int16ToDouble(window)
        return getPowerSpectrum(from: int16Window)
    }
    
    fileprivate func int16ToDouble(_ input:[Int16]) -> [Double]{
        return input.map{ Double($0)/Int16.max.cast() * maxDoubleSampleValue }
    }
    fileprivate func doubleToInt16(_ input:[Double]) -> [Int16]{
        return input.map{ (($0/maxDoubleSampleValue) * Double(Int16.max)).cast() }
    }
}
//Logging
extension FftwWrapper {
    fileprivate func printPowerSpectrum(_ result:UnsafeMutablePointer<fftw_complex>,WINDOW_SIZE:Int, MAX_AMPLITUDE:Double){
        let fftwRealPowerSpectrum = complexToReal(result,itemsCount: WINDOW_SIZE)
        
        for (i,mag) in fftwRealPowerSpectrum.enumerated() {
            let freqName = i < fftwRealPowerSpectrum.count/2 ?
                "\((i.cast() * SAMLE_RATE)/WINDOW_SIZE.cast()) Hz: " :
                "\(((fftwRealPowerSpectrum.count - i - 1).cast() * SAMLE_RATE)/WINDOW_SIZE.cast()) Hz: "
            print( freqName + getGraphString(mag , maxVal: MAX_AMPLITUDE, graphResolution: 150, onlyPositive: true) + "\(mag)")
        }
    }
    fileprivate func prinFftwComplex(_ ina:UnsafeMutablePointer<fftw_complex>,samplesCount:Int){
        for i in 0 ..< samplesCount {
            let
            real = getGraphString(ina.advanced(by: i).pointee.0),
            img = getGraphString(ina.advanced(by: i).pointee.1),
            time = "time placeholder"
//            time = i
//                .cast()
//                .truncatingRemainder(dividingBy: SAMLE_RATE) == 0
//                ? "time: \(i.cast()/SAMLE_RATE) sec ==="
//                : "time: \(i.cast()/SAMLE_RATE) sec"
            print( "ina0: \(real)    ina1: \( img)      \(time)" )
        }
    }
    fileprivate func getGraphString(_ val:Double, maxVal:Double = 150, graphResolution:Int = 30, onlyPositive:Bool = false) -> String{
        var
        currentVal:Int = ((val/maxVal) * graphResolution.cast()).cast(),
        charForDraw = "+" as Character
        
        
        if currentVal < 0{
            currentVal *= -1
            charForDraw = "-"
        }
        
        if currentVal > graphResolution {
            currentVal = graphResolution
        }
        
        let
        strFilled = String(repeating: String((charForDraw as Character)), count: currentVal),
        strEmpty = String(repeating: String((" " as Character)), count: graphResolution - currentVal),
        emptyGraphHalf =  String(repeating: String((" " as Character)), count: graphResolution)
        
        
        if onlyPositive {
            return "|" + strFilled + strEmpty
        }
        
        
        return
            charForDraw == "+" ?
                (emptyGraphHalf + "|" + strFilled + strEmpty) :
                (strEmpty + strFilled + "|" + emptyGraphHalf)
    }
}
