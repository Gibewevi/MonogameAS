using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;

namespace MonogameAS.Views;

/// <summary>
/// Placeholder minimal GalaxyView: draws label only (clean slate).
/// </summary>
public class GalaxyView : IView
{
    private const string Label = "Vue galaxie";

    public ViewMode Mode => ViewMode.Galaxy;

    public void Update(GameTime gameTime, MouseState mouse, MouseState previousMouse)
    {
        // No logic yet.
    }

    public void Draw(GameTime gameTime, RenderContext context)
    {
        var spriteBatch = context.SpriteBatch;
        spriteBatch.Begin();
        var viewport = context.ViewSize;
        var size = context.Font.MeasureString(Label);
        var position = new Vector2(viewport.X - size.X - 12, 12);
        spriteBatch.DrawString(context.Font, Label, position, Color.White);
        spriteBatch.End();
    }
}
