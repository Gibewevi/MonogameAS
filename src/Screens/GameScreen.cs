using System.Collections.Generic;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Input;
using MonogameAS;
using MonogameAS.UI;
using MonogameAS.Views;

namespace MonogameAS.Screens;

public class GameScreen : IScreen
{
    private readonly RenderContext _context;
    private readonly ViewSwitcher _viewSwitcher;
    private readonly Dictionary<ViewMode, IView> _views;
    private IView _currentView;

    public GameScreen(RenderContext context)
    {
        _context = context;
        _viewSwitcher = new ViewSwitcher(new Point(12, 12), ViewMode.Galaxy);
        _views = new Dictionary<ViewMode, IView>
        {
            { ViewMode.Galaxy, new GalaxyView() },
            { ViewMode.System, new SystemView() },
            { ViewMode.Planet, new PlanetView() }
        };
        _currentView = _views[_viewSwitcher.Current];
    }

    public void Update(GameTime gameTime, MouseState mouse, MouseState previousMouse)
    {
        var selected = _viewSwitcher.Update(mouse, previousMouse);
        if (selected.HasValue)
        {
            _currentView = _views[selected.Value];
        }

        _currentView.Update(gameTime, mouse, previousMouse);
    }

    public void Draw(GameTime gameTime)
    {
        _viewSwitcher.Draw(_context);
        _currentView.Draw(gameTime, _context);
    }
}
