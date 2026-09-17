using System.Collections.Generic;
using Microsoft.Xna.Framework;
using System;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;
using MonogameAS;

namespace MonogameAS.UI;

public class ViewSwitcher
{
    private readonly Dictionary<ViewMode, Button> _buttons;
    private static readonly Color TextColor = new(226, 234, 245);
    private static readonly Color Mint = new(153, 224, 206);

    public ViewSwitcher(Point origin, ViewMode startMode)
    {
        const int tabWidth = 120;
        const int tabHeight = 36;
        const int spacing = 8;

        Current = startMode;
        _buttons = new Dictionary<ViewMode, Button>
        {
            { ViewMode.Galaxy, new Button(new Rectangle(origin.X, origin.Y, tabWidth, tabHeight), "Galaxie") },
            { ViewMode.System, new Button(new Rectangle(origin.X + (tabWidth + spacing), origin.Y, tabWidth, tabHeight), "Système") },
            { ViewMode.Planet, new Button(new Rectangle(origin.X + 2 * (tabWidth + spacing), origin.Y, tabWidth, tabHeight), "Planète") }
        };
    }

    public ViewMode Current { get; private set; }

    public void SetCurrent(ViewMode mode)
    {
        Current = mode;
    }

    public bool ContainsPoint(Point logicalPosition)
    {
        foreach (var button in _buttons.Values)
            if (button.Bounds.Contains(logicalPosition)) return true;
        return false;
    }

    public ViewMode? Update(RenderContext context, MouseState currentMouse, MouseState previousMouse)
    {
        var logicalPos = context.ScreenToLogical(currentMouse.Position);
        var leftPressed = currentMouse.LeftButton == ButtonState.Pressed;
        var leftPrev = previousMouse.LeftButton == ButtonState.Pressed;
        foreach (var pair in _buttons)
        {
            if (pair.Value.Update(logicalPos, leftPressed, leftPrev))
            {
                Current = pair.Key;
                return Current;
            }
        }

        return null;
    }

    public void Draw(RenderContext context)
    {
        var spriteBatch = context.SpriteBatch;
        spriteBatch.Begin(samplerState: SamplerState.PointClamp);
        foreach (var pair in _buttons)
        {
            var button = pair.Value;
            var active = pair.Key == Current;
            var fill = active ? new Color(39, 65, 72) : new Color(23, 30, 49);
            var border = active ? new Color(116, 190, 178) : new Color(53, 66, 92);
            if (button.IsHover)
            {
                fill = Color.Lerp(fill, new Color(96, 121, 151), button.IsPressed ? 0.14f : 0.27f);
                border = active ? Mint : new Color(119, 140, 169);
            }
            DrawTab(context, button.Bounds, fill, border, active);
            var iconColor = active ? Mint : new Color(156, 168, 198);
            DrawIcon(context, pair.Key, new Point(button.Bounds.X + 17, button.Bounds.Y + 17), iconColor);
            var label = pair.Key switch { ViewMode.Galaxy => "Galaxie", ViewMode.System => "Système", _ => "Planète" };
            const float scale = 0.64f;
            var textSize = context.Font.MeasureString(label) * scale;
            var position = new Vector2(button.Bounds.X + 33,
                button.Bounds.Y + MathF.Floor((button.Bounds.Height - textSize.Y) * 0.5f) - 1);
            spriteBatch.DrawString(context.Font, label, position, active ? TextColor : new Color(186, 199, 219),
                0f, Vector2.Zero, scale, SpriteEffects.None, 0f);
        }
        spriteBatch.End();
    }

    private static void DrawTab(RenderContext context, Rectangle bounds, Color fill, Color border, bool active)
    {
        var batch = context.SpriteBatch;
        var pixel = context.Pixel;
        batch.Draw(pixel, new Rectangle(bounds.X + 3, bounds.Y, bounds.Width - 6, bounds.Height), fill);
        batch.Draw(pixel, new Rectangle(bounds.X, bounds.Y + 3, bounds.Width, bounds.Height - 6), fill);
        batch.Draw(pixel, new Rectangle(bounds.X + 1, bounds.Y + 1, bounds.Width - 2, bounds.Height - 2), fill);
        batch.Draw(pixel, new Rectangle(bounds.X + 3, bounds.Y, bounds.Width - 6, 1), border);
        batch.Draw(pixel, new Rectangle(bounds.X + 3, bounds.Bottom - 1, bounds.Width - 6, 1), border * 0.6f);
        batch.Draw(pixel, new Rectangle(bounds.X, bounds.Y + 3, 1, bounds.Height - 6), border);
        batch.Draw(pixel, new Rectangle(bounds.Right - 1, bounds.Y + 3, 1, bounds.Height - 6), border * 0.6f);
        batch.Draw(pixel, new Rectangle(bounds.X + 1, bounds.Y + 1, 2, 1), border);
        batch.Draw(pixel, new Rectangle(bounds.X + 1, bounds.Y + 2, 1, 1), border);
        batch.Draw(pixel, new Rectangle(bounds.Right - 3, bounds.Y + 1, 2, 1), border);
        batch.Draw(pixel, new Rectangle(bounds.Right - 2, bounds.Y + 2, 1, 1), border);
        if (active)
            batch.Draw(pixel, new Rectangle(bounds.X + 31, bounds.Bottom - 4, bounds.Width - 42, 2), Mint * 0.8f);
    }

    private static void DrawIcon(RenderContext context, ViewMode mode, Point center, Color color)
    {
        var batch = context.SpriteBatch;
        var pixel = context.Pixel;
        if (mode == ViewMode.Galaxy)
        {
            batch.Draw(pixel, new Rectangle(center.X - 1, center.Y - 6, 2, 12), color);
            batch.Draw(pixel, new Rectangle(center.X - 6, center.Y - 1, 12, 2), color);
            batch.Draw(pixel, new Rectangle(center.X - 2, center.Y - 2, 4, 4), TextColor);
            batch.Draw(pixel, new Rectangle(center.X + 5, center.Y - 6, 2, 2), color * 0.7f);
            batch.Draw(pixel, new Rectangle(center.X - 7, center.Y + 5, 2, 2), color * 0.7f);
        }
        else if (mode == ViewMode.System)
        {
            batch.Draw(pixel, new Rectangle(center.X - 2, center.Y - 2, 4, 4), color);
            batch.Draw(pixel, new Rectangle(center.X - 4, center.Y - 6, 8, 1), color * 0.7f);
            batch.Draw(pixel, new Rectangle(center.X - 4, center.Y + 5, 8, 1), color * 0.7f);
            batch.Draw(pixel, new Rectangle(center.X - 6, center.Y - 3, 1, 6), color * 0.7f);
            batch.Draw(pixel, new Rectangle(center.X + 5, center.Y - 3, 1, 6), color * 0.7f);
            batch.Draw(pixel, new Rectangle(center.X + 3, center.Y - 5, 3, 3), TextColor);
        }
        else
        {
            batch.Draw(pixel, new Rectangle(center.X - 3, center.Y - 6, 6, 12), color);
            batch.Draw(pixel, new Rectangle(center.X - 5, center.Y - 4, 10, 8), color);
            batch.Draw(pixel, new Rectangle(center.X - 6, center.Y - 2, 12, 4), color);
            batch.Draw(pixel, new Rectangle(center.X - 3, center.Y - 4, 4, 3), TextColor * 0.8f);
            batch.Draw(pixel, new Rectangle(center.X + 1, center.Y, 4, 3), new Color(71, 120, 122));
            batch.Draw(pixel, new Rectangle(center.X - 2, center.Y + 3, 3, 2), new Color(71, 120, 122));
        }
    }
}

