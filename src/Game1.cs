using System;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;
using MonogameAS.Logging;
using MonogameAS.Screens;

namespace MonogameAS;

public class Game1 : Game
{
    private readonly GraphicsDeviceManager _graphics;
    private SpriteBatch _spriteBatch = default!;
    private SpriteFont _defaultFont = default!;
    private Texture2D _pixel = default!;
    private RenderContext _renderContext = default!;
    private IScreen? _currentScreen;
    private MouseState _previousMouse;

    public Game1()
    {
        _graphics = new GraphicsDeviceManager(this);
        Content.RootDirectory = "Content";
        IsMouseVisible = true;
        Logger.Initialize();
        AppDomain.CurrentDomain.UnhandledException += (_, e) =>
        {
            Logger.Error("Unhandled exception", e.ExceptionObject as Exception);
            Exit();
        };
        System.Threading.Tasks.TaskScheduler.UnobservedTaskException += (_, e) =>
        {
            Logger.Error("Unobserved task exception", e.Exception);
            e.SetObserved();
        };
    }

    protected override void Initialize()
    {
        _previousMouse = Mouse.GetState();
        base.Initialize();
    }

    protected override void LoadContent()
    {
        _spriteBatch = new SpriteBatch(GraphicsDevice);
        _defaultFont = Content.Load<SpriteFont>("Default");

        _pixel = new Texture2D(GraphicsDevice, 1, 1);
        _pixel.SetData(new[] { Color.White });

        _renderContext = new RenderContext(GraphicsDevice, _spriteBatch, _defaultFont, _pixel);
        ShowMainMenu();
    }

    protected override void Update(GameTime gameTime)
    {
        var mouse = Mouse.GetState();
        _currentScreen?.Update(gameTime, mouse, _previousMouse);
        _previousMouse = mouse;
        base.Update(gameTime);
    }

    protected override void Draw(GameTime gameTime)
    {
        GraphicsDevice.Clear(Color.CornflowerBlue);
        _currentScreen?.Draw(gameTime);
        base.Draw(gameTime);
    }

    private void ShowMainMenu()
    {
        Logger.Info("Switching to MainMenuScreen");
        _currentScreen = new MainMenuScreen(_renderContext, ShowGameScreen, Exit);
    }

    private void ShowGameScreen()
    {
        Logger.Info("Starting new game -> GameScreen");
        _currentScreen = new GameScreen(_renderContext);
    }
}

