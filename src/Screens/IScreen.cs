using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Input;

namespace MonogameAS.Screens;

public interface IScreen
{
    void Update(GameTime gameTime, MouseState mouse, MouseState previousMouse);
    void Draw(GameTime gameTime);
}

