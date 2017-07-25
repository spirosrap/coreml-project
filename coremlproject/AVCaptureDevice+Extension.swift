//
//  AppDelegate.swift
//  CoreMLSimple
//
//  Created by 杨萧玉 on 2017/6/9.
//  Copyright © 2017年 杨萧玉. All rights reserved.
//  Based on Shuichi Tsutsumi's Code
//  The following code is modified from https://github.com/yulingtianxia/Core-ML-Sample

import AVFoundation

extension AVCaptureDevice {
    
    //Set the format of the video with a specific fps value.
    func updateFormatWithPreferredVideoSpec(fps: Float64)
    {
        let availableFormats: [AVCaptureDevice.Format]
        availableFormats = availableFormatsFor(preferredFps: fps)
        
        var selectedFormat: AVCaptureDevice.Format?
        selectedFormat = formatWithHighestResolution(availableFormats)
        print("selected format: \(String(describing: selectedFormat))")
        
        if let selectedFormat = selectedFormat {
            do {
                try lockForConfiguration()
            }
            catch {
                fatalError("")
            }
            activeFormat = selectedFormat
            
            activeVideoMinFrameDuration = CMTimeMake(1, Int32(fps))
            activeVideoMaxFrameDuration = CMTimeMake(1, Int32(fps))
            unlockForConfiguration()
        }
    }
    //Return all the available formats for the video
    private func availableFormatsFor(preferredFps: Float64) -> [AVCaptureDevice.Format] {
        var availableFormats: [AVCaptureDevice.Format] = []
        for format in formats
        {
            let ranges = format.videoSupportedFrameRateRanges
            for range in ranges where range.minFrameRate <= preferredFps && preferredFps <= range.maxFrameRate
            {
                availableFormats.append(format)
            }
        }
        return availableFormats
    }
    // Select the format with the highest resolution
    private func formatWithHighestResolution(_ availableFormats: [AVCaptureDevice.Format]) -> AVCaptureDevice.Format?
    {
        var maxWidth: Int32 = 0
        var selectedFormat: AVCaptureDevice.Format?
        for format in availableFormats {
            let desc = format.formatDescription
            let dimensions = CMVideoFormatDescriptionGetDimensions(desc)
            let width = dimensions.width
            if width >= maxWidth {
                maxWidth = width
                selectedFormat = format
            }
        }
        return selectedFormat
    }
    
    
}
