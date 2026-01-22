using System;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;
using MonogameAS;
using MonogameAS.UI;
using MonogameAS.Logging;

namespace MonogameAS.Screens;

public class MainMenuScreen : IScreen
{
    private readonly RenderContext _context;
    private readonly Action _startGame;
    private readonly Action _exitGame;
    private readonly Button _newGameButton;
    private readonly Button _quitButton;
    private Point _lastViewportSize;

    public MainMenuScreen(RenderContext context, Action startGame, Action exitGame)
    {
        _context = context;
        _startGame = startGame;
        _exitGame = exitGame;
        _newGameButton = new Button(Rectangle.Empty, "Nouvelle partie");
        _quitButton = new Button(Rectangle.Empty, "Quitter");
        RefreshLayout();
    }

    public void Update(GameTime gameTime, MouseState mouse, MouseState previousMouse)
    {
        RefreshLayout();

        if (_newGameButton.Update(mouse, previousMouse))
        {
            Logging.Logger.Info("MainMenu: Nouvelle partie clicked");
            _startGame();
        }

        if (_quitButton.Update(mouse, previousMouse))
        {
            Logging.Logger.Info("MainMenu: Quitter clicked");
            _exitGame();
        }
    }

    public void Draw(GameTime gameTime)
    {
        var spriteBatch = _context.SpriteBatch;
        spriteBatch.Begin();

        var buttonColor = new Color(60, 60, 75);
        var textColor = Color.White;
        _newGameButton.Draw(_context, buttonColor, textColor);
        _quitButton.Draw(_context, buttonColor, textColor);

        spriteBatch.End();
    }

    private void RefreshLayout()
    {
        var viewportSize = _context.ViewSize;
        if (viewportSize == _lastViewportSize)
            return;

        _lastViewportSize = viewportSize;
        const int buttonWidth = 240;
        const int buttonHeight = 60;
        const int gap = 18;

        var totalHeight = buttonHeight * 2 + gap;
        var startX = (viewportSize.X - buttonWidth) / 2;
        var startY = (viewportSize.Y - totalHeight) / 2;

        _newGameButton.Bounds = new Rectangle(startX, startY, buttonWidth, buttonHeight);
        _quitButton.Bounds = new Rectangle(startX, startY + buttonHeight + gap, buttonWidth, buttonHeight);
    }
}

