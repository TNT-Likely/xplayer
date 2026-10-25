// macOS 13+: measure captured system PCM energy without saving audio or images.
// swiftc -parse-as-library system_audio_meter.swift -o /tmp/xplayer-audio-meter
// /tmp/xplayer-audio-meter [PID]
// Requires existing Screen & System Audio Recording permission. For a per-device
// acceptance run, stop the other test players before using the global meter.
import Foundation
import ScreenCaptureKit
import CoreMedia
import CoreAudio
import CoreGraphics
import AVFoundation

final class Meter: NSObject, SCStreamOutput {
    let lock = NSLock()
    var samples = 0
    var energy: Double = 0
    var peak: Double = 0
    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .audio, sampleBuffer.isValid,
              let description = sampleBuffer.formatDescription,
              let format = CMAudioFormatDescriptionGetStreamBasicDescription(description) else { return }
        let audioFormat=AVAudioFormat(cmAudioFormatDescription:description)
        guard let pcm=AVAudioPCMBuffer(pcmFormat:audioFormat,frameCapacity:AVAudioFrameCount(sampleBuffer.numSamples)) else {return}
        pcm.frameLength=AVAudioFrameCount(sampleBuffer.numSamples)
        let status=CMSampleBufferCopyPCMDataIntoAudioBufferList(sampleBuffer,at:0,frameCount:Int32(sampleBuffer.numSamples),into:pcm.mutableAudioBufferList)
        guard status == noErr else { print("COPY_ERROR",status); return }
        var e: Double = 0, p: Double = 0, n = 0
        for buffer in UnsafeMutableAudioBufferListPointer(pcm.mutableAudioBufferList) {
            guard let data = buffer.mData else { continue }
            if format.pointee.mFormatFlags & kAudioFormatFlagIsFloat != 0 && format.pointee.mBitsPerChannel == 32 {
                let values = data.assumingMemoryBound(to: Float.self)
                let count = Int(buffer.mDataByteSize) / 4
                for i in 0..<count { let v=Double(values[i]); if v.isFinite { e += v*v; p=max(p,abs(v)); n += 1 } }
            }
        }
        lock.lock(); samples += n; energy += e; peak=max(peak,p); lock.unlock()
    }
    func result() -> [String:Any] {
        lock.lock(); defer {lock.unlock()}
        let rms = samples == 0 ? 0 : sqrt(energy/Double(samples))
        return ["samples":samples,"rms":rms,"peak":peak,"rmsDbFS":20*log10(max(rms,1e-12))]
    }
}
@main struct Main {
 static func main() async throws {
    guard CGPreflightScreenCaptureAccess() else {
        throw NSError(domain:"XPlayerAudioMeter",code:1,userInfo:[NSLocalizedDescriptionKey:"Screen & System Audio Recording permission is required"])
    }
    let content = try await SCShareableContent.excludingDesktopWindows(false,onScreenWindowsOnly:false)
    guard let display=content.displays.first else { return }
    let requestedPID = CommandLine.arguments.dropFirst().first.flatMap(Int32.init)
    let filter: SCContentFilter
    if let pid=requestedPID {
        guard let application=content.applications.first(where:{$0.processID==pid}) else {
            throw NSError(domain:"XPlayerAudioMeter",code:2,userInfo:[NSLocalizedDescriptionKey:"Requested application PID is not available"])
        }
        filter=SCContentFilter(display:display,including:[application],exceptingWindows:[])
        print("audio process filter",pid,application.applicationName)
    } else {
        filter=SCContentFilter(display:display,excludingApplications:[],exceptingWindows:[])
        print("global audio meter")
    }
    let config=SCStreamConfiguration(); config.width=16;config.height=16
    config.minimumFrameInterval=CMTime(value:1,timescale:1)
    config.capturesAudio=true;config.sampleRate=48000;config.channelCount=2
    config.excludesCurrentProcessAudio=true;config.showsCursor=false
    let meter=Meter();let stream=SCStream(filter:filter,configuration:config,delegate:nil)
    try stream.addStreamOutput(meter,type:.audio,sampleHandlerQueue:DispatchQueue(label:"xplayer.audio-meter"))
    try await stream.startCapture()
    for i in 0..<12 { try await Task.sleep(for:.seconds(1));var r=meter.result();r["second"]=i+1;let data=try JSONSerialization.data(withJSONObject:r,options:[.sortedKeys]);print(String(data:data,encoding:.utf8)!) }
    try await stream.stopCapture()
 }
}
