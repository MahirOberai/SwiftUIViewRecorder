import AVFoundation
import UIKit
import Combine
import CoreMedia

extension Array where Element == URL {
    
    private func makeUniqueTempVideoURL() -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = ProcessInfo.processInfo.globallyUniqueString
        return tempDir.appendingPathComponent(fileName).appendingPathExtension("mov")
    }
        
//    private var frameSize: CGSize {
//        CGSize(width: (first?.size.width ?? 0) * UIScreen.main.scale,
//               height: (first?.size.height ?? 0) * UIScreen.main.scale)
//    }
    
    private func videoSettings(frameSize: CGSize, codecType: AVVideoCodecType) -> [String: Any] {
        return [
            AVVideoCodecKey: codecType,
            AVVideoWidthKey: frameSize.width,
            AVVideoHeightKey: frameSize.height
        ]
    }
    
    private var pixelAdaptorAttributes: [String: Any] {
        [
            kCVPixelBufferPixelFormatTypeKey as String : Int(kCMPixelFormat_32BGRA)
        ]
    }
    
    /**
     Convert array of `UIImage`s to QuickTime video.
     
     This method runs on a Main queue by default.
     Video generation is a time consuming process, subscribe on a different background queue for better performance.
     
     Video file is generated in a temporary directory. It's a calling code responsibility to unlink the file once not needed.
     
     - Precondition: `framesPerSecond` must be greater than 0
     
     - Parameter framesPerSecond: video FPS. How many samples are presented per second.
     - Parameter codecType: video codec to use. By default is H264. See `AVVideoCodecType` for other available options.
     
     - Returns: Future URL of a generated video file or Error
     */

//    func toVideo(framesPerSecond: Double,
//                 codecType: AVVideoCodecType = .h264) -> Future<URL?, Error> {
//
//        return Future<URL?, Error> { promise in
//            
//            guard self.count > 0 else {
//                promise(.failure(UIImagesToVideoError.noFrames))
//                return
//            }
//            
//            guard framesPerSecond > 0 else {
//                promise(.failure(UIImagesToVideoError.invalidFramesPerSecond))
//                return
//            }
//
//            let pixelAdaptorAttributes: [String: Any] = [
//                kCVPixelBufferPixelFormatTypeKey as String : Int(kCVPixelFormatType_32BGRA)
//            ]
//            
//            guard let firstImageURL = self.first, let firstImage = UIImage(contentsOfFile: firstImageURL.path) else {
//                // Handle error appropriately here
//                print("Error loading first image")
//                return promise(.failure(UIImagesToVideoError.noFrames))
//            }
//            
//            let frameSize: CGSize = CGSize(width: firstImage.size.width * UIScreen.main.scale,
//                                           height: firstImage.size.height * UIScreen.main.scale)
//            
////            let videoSettings: [String: Any] = [
////                AVVideoCodecKey: codecType,
////                AVVideoWidthKey: frameSize.width,
////                AVVideoHeightKey: frameSize.height
////            ]
//            
//            let url = self.makeUniqueTempVideoURL()
//            
//            do {
//                let writer = try AVAssetWriter(outputURL: url, fileType: .mov)
//                print("Asset writer status: \(writer.status.rawValue)")
//
//                let input = AVAssetWriterInput(mediaType: .video, outputSettings: self.videoSettings(frameSize: frameSize, codecType: codecType))
//                
//                guard writer.canAdd(input) else {
//                    promise(.failure(UIImagesToVideoError.internalError))
//                    return
//                }
//                writer.add(input)
//                
//                let pixelAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: pixelAdaptorAttributes)
//
//                let writerQueue = DispatchQueue(label: "assetWriterQueue")
//                writerQueue.async {
////                    do {
//                        writer.startWriting()
//                        writer.startSession(atSourceTime: CMTime.zero)
//                        
//                        if let error = writer.error {
//                            print("Error after starting the writer: \(error)")
//                        }
//                        
//                        var frameIndex: Int = 0
//                        let group = DispatchGroup()
//                        
//                        input.observe(\.isReadyForMoreMediaData, options: [.new]) { input, change in
//                            print("Is ready for more media data: \(input.isReadyForMoreMediaData)")
//                        }
//                        
//                        while frameIndex < self.count {
//                            group.enter()
//                            
//                            if input.isReadyForMoreMediaData {
//                                
//                                let frameURL = self[frameIndex]
//                                if frameIndex < self.count {
//                                    if let retrievedImage = UIImage.loadImageFromDisk(at: frameURL) {
//                                        UIGraphicsBeginImageContextWithOptions(retrievedImage.size, false, retrievedImage.scale)
//                                        retrievedImage.draw(in: CGRect(origin: .zero, size: retrievedImage.size))
//                                        guard let redrawnImage = UIGraphicsGetImageFromCurrentImageContext() else {
//                                            print("Error redrawing the image")
//                                            return promise(.failure(UIImagesToVideoError.internalError))
//                                        }
//                                        UIGraphicsEndImageContext()
//                                        if let buffer = redrawnImage.toSampleBuffer(frameIndex: frameIndex, framesPerSecond: framesPerSecond) {
//                                            pixelAdaptor.append(CMSampleBufferGetImageBuffer(buffer)!,
//                                                                withPresentationTime: CMSampleBufferGetOutputPresentationTimeStamp(buffer))
//                                            frameIndex += 1
//                                            group.leave()
//                                        } else {
//                                            group.leave()
//                                        }
//                                      
//                                        
//                                    }
//                                } else {
//                                    print("Error loading image from URL: \(frameURL)")
//                                    group.leave()
//                                }
//                            } else {
//                                group.wait()
//                            }
//                        }
//                        input.markAsFinished()
//
//                                
//                        writer.finishWriting {
//                            switch writer.status {
//                            case .completed:
//                                print("[Media Renderer]: successfully finished writing video \(url)")
//                                promise(.success(url))
//                            default:
//                                let error = writer.error ?? UIImagesToVideoError.internalError
//                                print("[Media Renderer]: finished writing video without success \(error)")
//                                promise(.failure(error))
//                            }
//
//                            // Cleanup...
//                            for frameURL in self {
//                                do {
//                                    try FileManager.default.removeItem(at: frameURL)
//                                } catch {
//                                    print("Error deleting frame from disk: \(error)")
//                                }
//                            }
//                        }
////                    } catch {
////                        promise(.failure(error))
////                        return
////                    }
//                    
//                }
//            } catch {
//                promise(.failure(error))
//                return
//            }
//        }
//    }

    
    func toVideo(framesPerSecond: Double,
                 codecType: AVVideoCodecType = .h264) -> Future<URL?, Error> {
        print("[Media Renderer]: generating video framesPerSecond=\(framesPerSecond), codecType=\(codecType.rawValue)")
        
        return Future<URL?, Error> { promise in
            guard self.count > 0 else {
                promise(.failure(UIImagesToVideoError.noFrames))
                return
            }
            
            guard framesPerSecond > 0 else {
                promise(.failure(UIImagesToVideoError.invalidFramesPerSecond))
                return
            }
            
            guard let firstImageURL = self.first, let firstImage = UIImage(contentsOfFile: firstImageURL.path) else {
                // Handle error appropriately here
                print("Error loading first image")
                return promise(.failure(UIImagesToVideoError.noFrames))
            }
            
            let frameSize: CGSize = CGSize(width: firstImage.size.width * UIScreen.main.scale,
                                           height: firstImage.size.height * UIScreen.main.scale)
            
           
//            var pixelFormat: OSType = kCVPixelFormatType_32BGRA

//            if let firstCGImage = firstImage.cgImage {
//                let alphaInfo = firstCGImage.alphaInfo
//                let bitmapInfo = firstCGImage.bitmapInfo
//                
//                switch (bitmapInfo.contains(.floatComponents), alphaInfo) {
//                case (false, .none), (false, .noneSkipLast):
//                    pixelFormat = kCVPixelFormatType_32ARGB
//                case (true, _):
//                    pixelFormat = kCVPixelFormatType_32BGRA
//                default:
//                    print("Unhandled pixel format: \(bitmapInfo), alphaInfo: \(alphaInfo)")
//                    return promise(.failure(UIImagesToVideoError.internalError))
//                }
//
//                print("Pixel format: \(pixelFormat ?? 0)")
//            }
//
//            guard let pixelFormatUnwrapped = pixelFormat else {
//                print("Error retrieving pixel format")
//                return promise(.failure(UIImagesToVideoError.internalError))
//            }

//            let pixelAdaptorAttributes: [String: Any] = [
//                kCVPixelBufferPixelFormatTypeKey as String : Int(pixelFormat)
//            ]

            let videoSettings = [
                AVVideoCodecKey: codecType,
                AVVideoWidthKey: frameSize.width,
                AVVideoHeightKey: frameSize.height
            ]

            let url = self.makeUniqueTempVideoURL()
            
            let writer: AVAssetWriter
            do {
                writer = try AVAssetWriter(outputURL: url, fileType: .mov)
            } catch {
                promise(.failure(error))
                return
            }
                    
            let input = AVAssetWriterInput(mediaType: .video,
                                           outputSettings: videoSettings)
                                
            if (writer.canAdd(input)) {
                writer.add(input)
            } else {
                promise(.failure(UIImagesToVideoError.internalError))
                return
            }
            
            let pixelAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input,
                                                                    sourcePixelBufferAttributes: pixelAdaptorAttributes)
            
            writer.startWriting()
            writer.startSession(atSourceTime: CMTime.zero)
            
            var frameIndex: Int = 0
            while frameIndex < self.count {
                if (input.isReadyForMoreMediaData) {
                    let frameURL = self[frameIndex]
                    if let retrievedImage = UIImage.loadImageFromDisk(at: frameURL) {
                        UIGraphicsBeginImageContextWithOptions(retrievedImage.size, false, retrievedImage.scale)
                        retrievedImage.draw(in: CGRect(origin: .zero, size: retrievedImage.size))
                        guard let redrawnImage = UIGraphicsGetImageFromCurrentImageContext() else {
                            print("Error redrawing the image")
                            return promise(.failure(UIImagesToVideoError.internalError))
                        }
                        UIGraphicsEndImageContext()
                        if let buffer = redrawnImage.toSampleBuffer(frameIndex: frameIndex, framesPerSecond: framesPerSecond) {
                            pixelAdaptor.append(CMSampleBufferGetImageBuffer(buffer)!,
                                                withPresentationTime: CMSampleBufferGetOutputPresentationTimeStamp(buffer))
                        }
                    }
                   

                    
                   
                    frameIndex += 1
                } else {
                    // Sleep for a short time before trying again to avoid 100% CPU usage
                    usleep(10000)  // sleep for 10ms
                }
            }
            input.markAsFinished()
            writer.finishWriting {
                switch writer.status {
                case .completed:
                    print("[Media Renderer]: successfully finished writing video \(url)")
                    promise(.success(url))
                    break
                default:
                    let error = writer.error ?? UIImagesToVideoError.internalError
                    print("[Media Renderer]: finished writing video without success \(error)")
                    promise(.failure(error))
                }
                
                // Cleanup: Delete the saved frames from the disk
                for frameURL in self {
                    do {
                        try FileManager.default.removeItem(at: frameURL)
                    } catch {
                        print("Error deleting frame from disk: \(error)")
                    }
                }
            }
        }
    }
    
//    func toVideo(framesPerSecond: Double,
//                 codecType: AVVideoCodecType = .h264) -> Future<URL?, Error> {
//
//        return Future<URL?, Error> { promise in
//            guard self.count > 0 else {
//                promise(.failure(UIImagesToVideoError.noFrames))
//                return
//            }
//            
//            guard framesPerSecond > 0 else {
//                promise(.failure(UIImagesToVideoError.invalidFramesPerSecond))
//                return
//            }
//
//            // Removed other checks for brevity...
//            
//            let pixelAdaptorAttributes: [String: Any] = [
//                kCVPixelBufferPixelFormatTypeKey as String : Int(kCVPixelFormatType_32BGRA) // Default to 32BGRA for debugging purposes.
//            ]
//
//            let videoSettings: [String: Any] = [
//                AVVideoCodecKey: codecType.rawValue,
//                AVVideoWidthKey: frameSize.width,
//                AVVideoHeightKey: frameSize.height
//            ]
//
//            let url = self.makeUniqueTempVideoURL()
//            
//            let writer: AVAssetWriter
//            do {
//                writer = try AVAssetWriter(outputURL: url, fileType: .mov)
//            } catch {
//                promise(.failure(error))
//                return
//            }
//
//            let input = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
//            
//            if writer.canAdd(input) {
//                writer.add(input)
//            } else {
//                promise(.failure(UIImagesToVideoError.internalError))
//                return
//            }
//
//            let pixelAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: pixelAdaptorAttributes)
//
//            // Ensure all writer operations are on the same dispatch queue for thread safety
//            let writerQueue = DispatchQueue(label: "assetWriterQueue")
//
//            writerQueue.async {
//                writer.startWriting()
//                writer.startSession(atSourceTime: CMTime.zero)
//                
//                let group = DispatchGroup()
//                group.enter()
//                
//                input.requestMediaDataWhenReady(on: writerQueue) {
//                    while input.isReadyForMoreMediaData {
//                        if frameIndex < self.count {
//                            let frameURL = self[frameIndex]
//                            if let retrievedImage = UIImage.loadImageFromDisk(at: frameURL) {
//                                //... Rest of your logic...
//                                frameIndex += 1
//                            }
//                        } else {
//                            input.markAsFinished()
//                            group.leave()
//                        }
//                    }
//                }
//                
//                group.wait()
//
//                writer.finishWriting {
//                    switch writer.status {
//                    case .completed:
//                        print("[Media Renderer]: successfully finished writing video \(url)")
//                        promise(.success(url))
//                    default:
//                        let error = writer.error ?? UIImagesToVideoError.internalError
//                        print("[Media Renderer]: finished writing video without success \(error)")
//                        promise(.failure(error))
//                    }
//                    
//                    // Cleanup...
//                }
//            }
//        }
//    }

    
    func createLoopedVideo(numLoops: Int = 10, framesPerSecond: Double, codecType: AVVideoCodecType = .h264) -> Future<URL?, Error> {
        return Future<URL?, Error> { promise in
            var videoURLs: [URL] = []
            
            var cancellables: [AnyCancellable] = []

            // Generate the video and append the URLs to the array
            for _ in 0..<numLoops {
                let cancellable =
                self.toVideo(framesPerSecond: framesPerSecond, codecType: codecType)
                    .sink(receiveCompletion: { _ in /* Placeholder closure */ }, receiveValue: { url in
                        if let url = url {
                            videoURLs.append(url)
                        }
                    })
                cancellables.append(cancellable)
            }

            // Concatenate the videos using AVAssetExportSession
            let composition = AVMutableComposition()
            let videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)

            for url in videoURLs {
                let asset = AVAsset(url: url)
                if let track = asset.tracks(withMediaType: .video).first {
                    try? videoTrack?.insertTimeRange(CMTimeRange(start: .zero, duration: asset.duration), of: track, at: composition.duration)
                }
            }

            // Export the concatenated composition to a new URL
            let outputURL = self.makeUniqueTempVideoURL()
            if let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) {
                exportSession.outputURL = outputURL
                exportSession.outputFileType = .mov
                exportSession.exportAsynchronously {
                    switch exportSession.status {
                    case .completed:
                        print("[Media Renderer]: successfully finished creating looped video with \(numLoops) loops \(outputURL)")
                        promise(.success(outputURL))
                    default:
                        promise(.failure(exportSession.error ?? UIImagesToVideoError.internalError))
                    }
                }
            } else {
                promise(.failure(UIImagesToVideoError.internalError))
            }
        }
    }
}

extension UIImage {
    func saveToDisk(fileName: String) -> URL? {
        let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let fileURL = temporaryDirectoryURL.appendingPathComponent(fileName)
        
        do {
            try self.pngData()?.write(to: fileURL)
            return fileURL
        } catch {
            print("Error saving image to disk: \(error)")
            return nil
        }
    }
    
    static func loadImageFromDisk(at url: URL) -> UIImage? {
        return UIImage(contentsOfFile: url.path)
    }
}



