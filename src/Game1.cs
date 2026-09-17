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
    private RenderTarget2D _canvas = default!;
    private static readonly Point LogicalSize = new(640, 360);
    private float _displayScale = 1f;
    private Rectangle _displayDest;

    public Game1()
    {
        _graphics = new GraphicsDeviceManager(this);
        Content.RootDirectory = "Content";
        IsMouseVisible = true;

        // Fenêtre adaptée à la résolution courante (pas plein écran).
        var mode = GraphicsAdapter.DefaultAdapter.CurrentDisplayMode;
        _graphics.PreferredBackBufferWidth = mode.Width;
        _graphics.PreferredBackBufferHeight = mode.Height;
        _graphics.IsFullScreen = false;
        _graphics.ApplyChanges();
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

        _canvas = new RenderTarget2D(GraphicsDevice, LogicalSize.X, LogicalSize.Y, false, SurfaceFormat.Color, DepthFormat.None, 0, RenderTargetUsage.PreserveContents);
        _renderContext = new RenderContext(GraphicsDevice, _spriteBatch, _defaultFont, _pixel, LogicalSize);
        ShowMainMenu();
    }

    protected override void Update(GameTime gameTime)
    {
        UpdateDisplayTransform();
        _renderContext.SetDisplayTransform(_displayScale, _displayDest);

        var mouse = Mouse.GetState();
        _currentScreen?.Update(gameTime, mouse, _previousMouse);
        _previousMouse = mouse;
        base.Update(gameTime);
    }

    protected override void Draw(GameTime gameTime)
    {
        // Sécurité: s'assurer que le transform est à jour pour ce frame de draw
        UpdateDisplayTransform();
        _renderContext.SetDisplayTransform(_displayScale, _displayDest);

        // rendu logique 640x360
        GraphicsDevice.SetRenderTarget(_canvas);
        GraphicsDevice.Clear(Color.CornflowerBlue);
        _currentScreen?.Draw(gameTime);

        // blit vers backbuffer en conservant le ratio
        GraphicsDevice.SetRenderTarget(null);
        GraphicsDevice.Clear(Color.Black);
        _spriteBatch.Begin(samplerState: SamplerState.PointClamp);
        _spriteBatch.Draw(_canvas, _displayDest, Color.White);
        _spriteBatch.End();

        base.Draw(gameTime);
    }

    private void UpdateDisplayTransform()
    {
        var bbWidth = GraphicsDevice.PresentationParameters.BackBufferWidth;
        var bbHeight = GraphicsDevice.PresentationParameters.BackBufferHeight;
        _displayScale = Math.Min(bbWidth / (float)LogicalSize.X, bbHeight / (float)LogicalSize.Y);
        var drawWidth = (int)(LogicalSize.X * _displayScale);
        var drawHeight = (int)(LogicalSize.Y * _displayScale);
        _displayDest = new Rectangle((bbWidth - drawWidth) / 2, (bbHeight - drawHeight) / 2, drawWidth, drawHeight);
    }

    private void ShowMainMenu()
    {
        Logger.Info("Switching to MainMenuScreen");
        (_currentScreen as IDisposable)?.Dispose();
        _currentScreen = new MainMenuScreen(_renderContext, ShowGameScreen, Exit);
    }

    private void ShowGameScreen()
    {
        Logger.Info("Starting new game -> GameScreen");
        (_currentScreen as IDisposable)?.Dispose();
        _currentScreen = new GameScreen(_renderContext);
    }

    protected override void UnloadContent()
    {
        (_currentScreen as IDisposable)?.Dispose();
        _currentScreen = null;
        _canvas?.Dispose();
        _pixel?.Dispose();
        _spriteBatch?.Dispose();
        base.UnloadContent();
    }
}
