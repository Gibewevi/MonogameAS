using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace MonogameAS;

public sealed class RenderContext
{
    public RenderContext(GraphicsDevice graphicsDevice, SpriteBatch spriteBatch, SpriteFont font, Texture2D pixel, Point logicalSize)
    {
        GraphicsDevice = graphicsDevice;
        SpriteBatch = spriteBatch;
        Font = font;
        Pixel = pixel;
        LogicalSize = logicalSize;
        _screenDest = new Rectangle(0, 0, logicalSize.X, logicalSize.Y);
    }

    public GraphicsDevice GraphicsDevice { get; }
    public SpriteBatch SpriteBatch { get; }
    public SpriteFont Font { get; }
    public Texture2D Pixel { get; }

    /// <summary>Résolution logique fixe (ex: 640x360) utilisée par toutes les vues.</summary>
    public Point LogicalSize { get; }

    /// <summary>Alias pour compatibilité existante.</summary>
    public Point ViewSize => LogicalSize;

    private float _screenScale = 1f;
    private Rectangle _screenDest;

    /// <summary>
    /// Met à jour la transformation écran -> résolution logique (letterboxing/scaling).
    /// Doit être appelée par Game1 avant Update/Draw.
    /// </summary>
    public void SetDisplayTransform(float scale, Rectangle destination)
    {
        _screenScale = scale;
        _screenDest = destination;
    }

    /// <summary>
    /// Convertit une coordonnée écran (pixels physiques) vers l'espace logique 640x360.
    /// Retourne (-1,-1) si en dehors de la zone letterbox.
    /// </summary>
    public Point ScreenToLogical(Point screenPos)
    {
        if (!_screenDest.Contains(screenPos))
            return new Point(-1, -1);

        var lx = (int)((screenPos.X - _screenDest.X) / _screenScale);
        var ly = (int)((screenPos.Y - _screenDest.Y) / _screenScale);
        return new Point(lx, ly);
    }
}

