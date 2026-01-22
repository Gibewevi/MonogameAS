using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Input;
using MonogameAS;

namespace MonogameAS.Views;

public interface IView
{
    ViewMode Mode { get; }
    void Update(GameTime gameTime, MouseState mouse, MouseState previousMouse);
    void Draw(GameTime gameTime, RenderContext context);
}

