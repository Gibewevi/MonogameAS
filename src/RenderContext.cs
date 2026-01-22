using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace MonogameAS;

public sealed class RenderContext
{
    public RenderContext(GraphicsDevice graphicsDevice, SpriteBatch spriteBatch, SpriteFont font, Texture2D pixel)
    {
        GraphicsDevice = graphicsDevice;
        SpriteBatch = spriteBatch;
        Font = font;
        Pixel = pixel;
    }

    public GraphicsDevice GraphicsDevice { get; }
    public SpriteBatch SpriteBatch { get; }
    public SpriteFont Font { get; }
    public Texture2D Pixel { get; }

    public Point ViewSize => new(GraphicsDevice.Viewport.Width, GraphicsDevice.Viewport.Height);
}

