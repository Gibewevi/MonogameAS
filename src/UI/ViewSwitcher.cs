using System.Collections.Generic;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Input;
using MonogameAS;

namespace MonogameAS.UI;

public class ViewSwitcher
{
    private readonly Dictionary<ViewMode, Button> _buttons;
    private readonly Color _tabColor = new(70, 70, 82);
    private readonly Color _textColor = Color.White;

    public ViewSwitcher(Point origin, ViewMode startMode)
    {
        const int tabWidth = 120;
        const int tabHeight = 36;
        const int spacing = 8;

        Current = startMode;
        _buttons = new Dictionary<ViewMode, Button>
        {
            { ViewMode.Galaxy, new Button(new Rectangle(origin.X, origin.Y, tabWidth, tabHeight), "Galaxy") },
            { ViewMode.System, new Button(new Rectangle(origin.X + (tabWidth + spacing), origin.Y, tabWidth, tabHeight), "System") },
            { ViewMode.Planet, new Button(new Rectangle(origin.X + 2 * (tabWidth + spacing), origin.Y, tabWidth, tabHeight), "Planet") }
        };
    }

    public ViewMode Current { get; private set; }

    public ViewMode? Update(MouseState currentMouse, MouseState previousMouse)
    {
        foreach (var pair in _buttons)
        {
            if (pair.Value.Update(currentMouse, previousMouse))
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
        spriteBatch.Begin();
        foreach (var pair in _buttons)
        {
            var button = pair.Value;
            var color = pair.Key == Current ? new Color(90, 110, 200) : _tabColor;
            button.Draw(context, color, _textColor);
        }
        spriteBatch.End();
    }
}

