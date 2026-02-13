/// Protocol for rendering backends (Metal, SpriteKit).
/// Each renderer implements this to consume `RenderCommand`s.
public protocol RenderPipeline: Sendable {
    /// Submit a batch of render commands for the current frame.
    func render(commands: [RenderCommand]) async

    /// Resize the rendering surface.
    func resize(width: Float, height: Float) async
}
