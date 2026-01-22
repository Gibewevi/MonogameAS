using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Input;
using MonogameAS;

namespace MonogameAS.Views;

public class SystemView : IView
{
    private const string Label = "Vue système";

    public ViewMode Mode => ViewMode.System;

    public void Update(GameTime gameTime, MouseState mouse, MouseState previousMouse)
    {
        // System logic will be added later.
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

