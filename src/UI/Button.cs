using System;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;
using MonogameAS;

namespace MonogameAS.UI;

public class Button
{
    private readonly string _label;

    public Button(Rectangle bounds, string label)
    {
        Bounds = bounds;
        _label = label;
    }

    public Rectangle Bounds { get; set; }
    public bool IsHover { get; private set; }
    public bool IsPressed { get; private set; }

    public bool Update(MouseState currentMouse, MouseState previousMouse)
    {
        IsHover = Bounds.Contains(currentMouse.Position);
        IsPressed = IsHover && currentMouse.LeftButton == ButtonState.Pressed;
        var wasReleased = previousMouse.LeftButton == ButtonState.Released;
        var nowPressed = currentMouse.LeftButton == ButtonState.Pressed;
        return IsHover && wasReleased && nowPressed;
    }

    public void Draw(RenderContext context, Color baseColor, Color textColor)
    {
        var spriteBatch = context.SpriteBatch;
        var fillColor = baseColor;
        if (IsPressed)
        {
            fillColor = new Color((byte)(baseColor.R - 10 < 0 ? 0 : baseColor.R - 10),
                                  (byte)(baseColor.G - 10 < 0 ? 0 : baseColor.G - 10),
                                  (byte)(baseColor.B - 10 < 0 ? 0 : baseColor.B - 10),
                                  baseColor.A);
        }
        else if (IsHover)
        {
            fillColor = new Color((byte)Math.Min(baseColor.R + 15, 255),
                                  (byte)Math.Min(baseColor.G + 15, 255),
                                  (byte)Math.Min(baseColor.B + 15, 255),
                                  baseColor.A);
        }

        spriteBatch.Draw(context.Pixel, Bounds, fillColor);

        var textSize = context.Font.MeasureString(_label);
        var textPosition = new Vector2(
            Bounds.X + (Bounds.Width - textSize.X) / 2,
            Bounds.Y + (Bounds.Height - textSize.Y) / 2);

        spriteBatch.DrawString(context.Font, _label, textPosition, textColor);
    }
}

