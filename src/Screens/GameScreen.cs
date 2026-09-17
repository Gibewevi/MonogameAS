using System.Collections.Generic;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Input;
using MonogameAS;
using MonogameAS.UI;
using MonogameAS.Views;
using MonogameAS.State;
using MonogameAS.Planet;
using MonogameAS.Systems;

namespace MonogameAS.Screens;

public class GameScreen : IScreen, System.IDisposable
{
    private readonly RenderContext _context;
    private readonly ViewSwitcher _viewSwitcher;
    private readonly Dictionary<ViewMode, IView> _views;
    private IView _currentView;
    private readonly GameState _state = new();
    private readonly PlanetProvider _planetProvider = new();
    private readonly SystemProvider _systemProvider = new();
    private readonly SystemParams _systemParams = SystemParams.Default;
    private bool _openSystemRequested;
    private bool _tabPointerCaptured;

    public GameScreen(RenderContext context)
    {
        _context = context;
        _viewSwitcher = new ViewSwitcher(new Point(12, 12), ViewMode.Galaxy);
        _views = new Dictionary<ViewMode, IView>
        {
            { ViewMode.Galaxy, new GalaxyView(_context, _state, OnSunSelected, () => _openSystemRequested = true) },
            { ViewMode.System, new SystemView(_context, _state, _planetProvider, _systemProvider, _systemParams) },
            { ViewMode.Planet, new PlanetView(_context, _state, _planetProvider) }
        };
        _currentView = _views[_viewSwitcher.Current];
    }

    public void Update(GameTime gameTime, MouseState mouse, MouseState previousMouse)
    {
        var overTabs = _viewSwitcher.ContainsPoint(_context.ScreenToLogical(mouse.Position));
        if (overTabs && mouse.LeftButton == ButtonState.Pressed && previousMouse.LeftButton == ButtonState.Released)
            _tabPointerCaptured = true;

        var selected = _viewSwitcher.Update(_context, mouse, previousMouse);
        if (selected.HasValue)
            SetCurrent(selected.Value);

        if (overTabs || _tabPointerCaptured || selected.HasValue)
        {
            // A tab press, its drag and its release belong to navigation. The new view
            // still updates its content immediately, without inheriting the UI click.
            var neutral = NeutralMouse(mouse.ScrollWheelValue);
            _currentView.Update(gameTime, neutral, neutral);
        }
        else
            _currentView.Update(gameTime, mouse, previousMouse);

        if (mouse.LeftButton == ButtonState.Released)
            _tabPointerCaptured = false;

        // Galaxy callbacks run inside its Update: defer replacing the view until it returns.
        if (_openSystemRequested)
        {
            _openSystemRequested = false;
            SetCurrent(ViewMode.System);
            var neutral = NeutralMouse(mouse.ScrollWheelValue);
            _currentView.Update(gameTime, neutral, neutral);
        }
    }

    private void SetCurrent(ViewMode mode)
    {
        _viewSwitcher.SetCurrent(mode);
        _currentView = _views[mode];
        _state.CurrentView = mode;
    }

    private static MouseState NeutralMouse(int wheel) => new(-1, -1, wheel,
        ButtonState.Released, ButtonState.Released, ButtonState.Released,
        ButtonState.Released, ButtonState.Released);

    public void Draw(GameTime gameTime)
    {
        _currentView.Draw(gameTime, _context);
        _viewSwitcher.Draw(_context); // UI au-dessus du fond/visuels
    }

    public void Dispose()
    {
        foreach (var view in _views.Values)
            (view as System.IDisposable)?.Dispose();
        _views.Clear();
    }

    private void OnSunSelected(SunKey key)
    {
        // Mise à jour de la clé du soleil seulement ; le changement de vue se fait via le bouton.
        _state.SetSunKey(key);
        // System seed dérivé du soleil pour cohérence déterministe
        _state.SetSystemSeed((int)HashSeeds(key.Seed));
    }

    private static long HashSeeds(int s)
    {
        unchecked
        {
            var h = s ^ 0x9E3779B9;
            h ^= h << 13;
            h ^= h >> 17;
            h ^= h << 5;
            return h == 0 ? 1 : h;
        }
    }
}
