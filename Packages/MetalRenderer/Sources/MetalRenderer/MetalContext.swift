import Metal
import QuartzCore
import CoreEngine

/// Actor wrapping the Metal device, command queue, and pipeline states.
/// Serves as the single entry point for all Metal GPU operations.
public actor MetalContext: RenderPipeline {
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private var pipelineState: MTLRenderPipelineState?
    private var viewportSize: SIMD2<Float> = .zero

    /// Initialize with the default system Metal device.
    public init?() {
        guard let device = MTLCreateSystemDefaultDevice(),
              let queue = device.makeCommandQueue()
        else { return nil }
        self.device = device
        self.commandQueue = queue
    }

    /// Submit render commands for the current frame.
    public func render(commands: [RenderCommand]) async {
        // TODO: Implement Metal render pass encoding
    }

    /// Update the viewport size on surface resize.
    public func resize(width: Float, height: Float) async {
        viewportSize = SIMD2(width, height)
    }
}
