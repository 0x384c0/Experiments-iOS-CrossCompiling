//
//  SDLWrapper.swift
//  IOSExperiments
//
//  Created by 0x384c0 on 19.08.16.
//  Copyright © 2016 0x384c0 . All rights reserved.
//

import UIKit
import SDL
import ffmpeg

class SDLWrapper{
    fileprivate var
    renderer:OpaquePointer!,
    texture:OpaquePointer!,
    window:OpaquePointer!,
    event = UnsafeMutablePointer<SDL_Event>.allocate(capacity: 1),
    rect = UnsafeMutablePointer<SDL_Rect>.allocate(capacity: 1),
    //audio
    wanted_spec: SDL_AudioSpec = SDL_AudioSpec(),
    spec: SDL_AudioSpec = SDL_AudioSpec()
    
    func initSdl(){        // SDL init
        SDL_SetMainReady()
        if 0 > SDL_Init(UInt32(SDL_INIT_VIDEO | SDL_INIT_TIMER | SDL_INIT_AUDIO)) {
            print("Couldn't SDL_Init")
            return
        }
    }
    
    func createWindow(_ imageWidth:Int32,imageHeigh:Int32){
        // SDL has multiple window no use SDL_SetVideoMode for SDL_Surface
        window = SDL_CreateWindow(
            String(describing: type(of: self)),
            SDL_WINDOWPOS_UNDEFINED_MASK | 0,
            SDL_WINDOWPOS_UNDEFINED_MASK | 0,
            imageWidth,
            imageHeigh,
            SDL_WINDOW_SHOWN.rawValue | SDL_WINDOW_OPENGL.rawValue | SDL_WINDOW_BORDERLESS.rawValue
        )
        guard nil != window else {
            print("SDL: couldn't create window")
            return
        }
        renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_TARGETTEXTURE.rawValue)
        texture = SDL_CreateTexture(renderer, UInt32(SDL_PIXELFORMAT_IYUV), Int32(SDL_TEXTUREACCESS_STREAMING.rawValue), imageWidth, imageHeigh)
        
        rect.pointee = SDL_Rect(x: 0, y: 0, w: imageWidth, h: imageHeigh)
        
        SDL_SetTextureBlendMode(texture, SDL_BLENDMODE_BLEND)
        event.pointee = SDL_Event()
        
        let sizeSDL = UIScreen.main.bounds.size
        let ratio = (sizeSDL.width / sizeSDL.height) / (CGFloat(rect.pointee.w) / CGFloat(rect.pointee.h))
        var scale = CGSize()
        if 0 > ratio {
            scale.width = 1
            scale.height = 1 / ratio
        } else {
            scale.width = 1 / ratio
            scale.height = 1
        }
    }
    func destroyWindow(){
        defer {
            SDL_DestroyTexture(texture)
            SDL_DestroyRenderer(renderer)
            SDL_DestroyWindow(window)
        }
    }
    func putFrameInToWindow(_ convertedFrame:AVFrame){
        SDL_UpdateYUVTexture(
            texture,
            rect,
            convertedFrame.data.0,
            convertedFrame.linesize.0,
            convertedFrame.data.1,
            convertedFrame.linesize.1,
            convertedFrame.data.2,
            convertedFrame.linesize.2
        )
        SDL_RenderClear(renderer)
        SDL_RenderCopy(renderer, texture, rect, rect)
        SDL_RenderPresent(renderer)
    }
    func sdlEvent() -> Bool{
        if (SDL_PollEvent(event) != 0) {
            if (event.pointee.type == SDL_QUIT.rawValue) {
                return true
            }
        }
        return false
    }
    
}
extension SDLWrapper{
    
    static let samplesPerFrame:Uint16 = 4096/2
    
    func starPlayingFromBuffer(_ aCodecCtx:AVCodecContext){
        wanted_spec.channels = aCodecCtx.channels.cast()
        wanted_spec.format = AUDIO_S16LSB.cast()
        wanted_spec.freq = aCodecCtx.sample_rate
        wanted_spec.silence = 0
        wanted_spec.samples = SDLWrapper.samplesPerFrame
        wanted_spec.callback = SDLWrapper.audio_callback
        //wanted_spec.userdata = frame
        
        if SDL_OpenAudio(&wanted_spec, &spec) != 0{
            preconditionFailure("SDL_OpenAudio")
        }
        SDL_PauseAudio(0)
    }
    func stopPlayingFromBuffer(){
        SDL_PauseAudio(1)
        SDL_CloseAudio()
    }

    
    static var audio_callback: SDL_AudioCallback = { userdata, stream, len in
        if let frame = AudioBuffer.shared.get(){
            SDL_memcpy(stream, frame, SDLWrapper.samplesPerFrame.cast())
        }
    }
}

