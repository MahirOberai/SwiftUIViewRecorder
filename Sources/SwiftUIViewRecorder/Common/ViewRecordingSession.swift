import SwiftUI
import Combine

/**
 Session handler to manage recording process and receive resulting `Asset`.
 
 Session handler can not be reused once stopped. Start new recording session with a new handler instance.
 */
public class ViewRecordingSession<Asset>: ViewAssetRecordingSession {
    
    private let view: AnyView
    private let framesRenderer: ([UIKit.UIImage]) -> Future<(Asset?, UIImage), Error>
    
    private let useSnapshots: Bool
    private let delay: Double?
    private let duration: Double?
    private let framesPerSecond: Double
    
    private var isRecording: Bool = true
    private var frames: [ViewFrame] = []
    var backgroundImage: UIImage?

    
    private let resultSubject: PassthroughSubject<(Asset?, UIImage), ViewRecordingError> = PassthroughSubject()
    private var assetGenerationCancellable: AnyCancellable? = nil
    
    /**
     Initialize new view recording session.
     
     Note that each SwiftUI view is a _struct_, thus it's copied on every assignment.
     Video capturing happens off-screen on a view's copy and intended for animation to video conversion rather than live screen recording.
     
     Recording performance is much better when setting `useSnapshots` to `true`.
     But this feature is only available on a simulator due to security limitations.
     Use snapshotting when you need to record high-FPS animation on a simulator to render it as a video.
     
     - Precondition: `duration` must be either `nil` or greater than 0.
     - Precondition: `framesPerSecond` must be greater than 0.
     - Precondition: `useSnapshots` isn't available on a real iOS device.
     
     - Parameter view: some SwiftUI `View` to record
     - Parameter framesRenderer: some `FramesRenderer` implementation to render captured frames to resulting `Asset`
     - Parameter useSnapshots: significantly improves recording performance, but doesn't work on a real iOS device due to privacy limitations
     - Parameter duration: optional fixed recording duration time in seconds. If `nil`, then need to call `stopRecording()` method to stop recording session.
     - Parameter framesPerSecond: number of frames to capture per second
     
     - Throws: `ViewRecordingError` if preconditions aren't met
     */
    public init<V: SwiftUI.View, Renderer: FramesRenderer>(view: V,
                                                           framesRenderer: Renderer,
                                                           useSnapshots: Bool = false,
                                                           delay: Double? = nil,
                                                           duration: Double? = nil,
                                                           framesPerSecond: Double) throws where Renderer.Asset == Asset {
        guard duration == nil || duration! > 0
            else { throw ViewRecordingError.illegalDuration }
        guard framesPerSecond > 0
            else { throw ViewRecordingError.illegalFramesPerSecond }
        
        self.view = AnyView(view)
        self.delay = delay
        self.duration = duration
        self.framesPerSecond = framesPerSecond
        self.useSnapshots = useSnapshots
        
        self.framesRenderer = { images in
            framesRenderer.render(frames: images, framesPerSecond: 30)
        }
        
        recordView()
    }
    
    /// Subscribe to receive generated `Asset` or generation `ViewRecordingError`
    public var resultPublisher: AnyPublisher<(Asset?, UIImage), ViewRecordingError> {
        resultSubject
            .eraseToAnyPublisher()
    }
    
    /// Stop current recording session and start `Asset` generation
    public func stopRecording() -> Void {
        guard isRecording else { return }
        
        print("[DZ Media Renderer]: stop recording")
        isRecording = false
        generateAsset()
    }
    
    private var fixedFramesCount: Int? {
        duration != nil ? Int(duration! * framesPerSecond) : nil
    }
    
    private var allFramesCaptured: Bool {
        fixedFramesCount != nil && frames.count >= fixedFramesCount!
    }
    
    private var description: String {
        (duration != nil ? "\(duration!) seconds," : "")
            + (fixedFramesCount != nil ? " \(fixedFramesCount!) frames," : "")
        + " \(framesPerSecond) fps image capture, video rendered at 30 fps"
    }
    
    private func recordView() -> Void {
        DispatchQueue.main.async {
            print("[DZ Media Renderer]: placed uiView from swiftUI view waiting \(self.delay ?? 0.0) seconds delay")
            let uiView = self.view.placeUIView()
            DispatchQueue.main.asyncAfter(deadline: .now() + (self.delay ?? 0.0)) {
                print("[DZ Media Renderer]: start recording \(self.description)")
                Timer.scheduledTimer(withTimeInterval: 1 / self.framesPerSecond, repeats: true) { timer in
                    if (!self.isRecording) {
                        timer.invalidate()
                        uiView.removeFromSuperview()
                    } else {
                        if self.useSnapshots, let snapshotView = uiView.snapshotView(afterScreenUpdates: false) {
                            self.frames.append(ViewFrame(snapshot: snapshotView))
                        } else {
                            self.frames.append(ViewFrame(image: uiView.asImage(afterScreenUpdates: true)))
                        }
                        
                        if (self.allFramesCaptured) {
                            self.stopRecording()
                        }
                    }
                }
            }
        }
    }
    
    private func generateAsset() -> Void {
        assetGenerationCancellable?.cancel()
              
        DispatchQueue.global(qos: .userInitiated).async {
            let frameImages = self.frames.map { $0.render() }
            print("[DZ Media Renderer]: rendered \(frameImages.count) frames")
            self.assetGenerationCancellable = self.framesRenderer(frameImages)
                .mapError { error in ViewRecordingError.renderingError(reason: error.localizedDescription) }
                .subscribe(self.resultSubject)
        }
    }
}
