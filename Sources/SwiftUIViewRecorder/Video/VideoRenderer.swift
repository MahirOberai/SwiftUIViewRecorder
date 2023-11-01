import UIKit
import UIImageExtensions
import Combine

class VideoRenderer: FramesRenderer {
    typealias Asset = URL
    
//    func render(frames: [UIImage], framesPerSecond: Double) -> Future<URL?, Error> {
//        frames.toVideo(framesPerSecond: framesPerSecond)
//    }
    
    func render(frameURLs: [URL], framesPerSecond: Double) -> Future<URL?, Error> {
        frameURLs.toVideo(framesPerSecond: framesPerSecond)
    }
    
    

}
