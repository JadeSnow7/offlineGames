import Foundation

/// Commands issued by game logic to the rendering layer.
/// The renderer consumes these each frame to draw the scene.
public enum RenderCommand: Sendable {
    /// Clear the screen with a given color.
    case clear(r: Float, g: Float, b: Float, a: Float)

    /// Draw a filled rectangle.
    case fillRect(x: Float, y: Float, width: Float, height: Float,
                  r: Float, g: Float, b: Float, a: Float)

    /// Draw a filled circle.
    case fillCircle(centerX: Float, centerY: Float, radius: Float,
                    r: Float, g: Float, b: Float, a: Float)

    /// Draw a line segment.
    case drawLine(x1: Float, y1: Float, x2: Float, y2: Float,
                  r: Float, g: Float, b: Float, a: Float, lineWidth: Float)

    /// Draw a sprite/texture at a position.
    case drawSprite(name: String, x: Float, y: Float, width: Float, height: Float)

    /// Draw text.
    case drawText(text: String, x: Float, y: Float, size: Float,
                  r: Float, g: Float, b: Float, a: Float)
}
