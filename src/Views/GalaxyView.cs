using System;
using System.Collections.Generic;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;
using MonogameAS.Galaxy;
using MonogameAS.Rendering;
using MonogameAS.State;

namespace MonogameAS.Views;

/// <summary>A pixel star chart with stable selection, explicit exploration and anchored navigation.</summary>
public partial class GalaxyView : IView, IDisposable
{
    // Generation constants and stellar identities intentionally match the existing galaxy.
    private const int TileSize = 32;
    private const int StartRadius = 1;
    private static readonly Color StartColor = new(61, 84, 123);
    private static readonly Color DiscoverColor = new(71, 113, 118);
    private const float NoiseFreq = 0.08f;
    private const float FillMin = 0.05f;
    private const float FillMax = 0.65f;
    private const float DensityScale = 0.45f;
    private const int CandidateStep = 8;
    private const float CandidateJitter = 3f;
    private const float SunRadius = 4f;
    private const float BorderMargin = SunRadius + 0.5f;
    private const float MinDist = 2f * SunRadius + 0.6f;
    private const int MaxSunsPerTile = 4;
    private const int Lod0Size = 8;
    private const int LodSteps = 3;
    private const int SolarEffectsMinZoom = 3;
    // One prominence unfolds over roughly three to five real minutes.
    private const double SolarAnimationSpeed = 0.04d;
    private const int WorldSeed = 123456789;
    private static readonly int[] SunSizeOptions = { 8, 10, 12, 14, 16, 18, 20, 22 };
    private static readonly string[] StarNames = { "Luma", "Mira", "Opale", "Nova", "Sélène", "Aster", "Nima", "Iris", "Elio", "Azura", "Néa", "Solis" };

    private readonly float[] _zoomLevels = { 1f, 2f, 3f, 4f };
    private int _currentZoomIndex = 1;
    private float CurrentZoom => _zoomLevels[_currentZoomIndex];
    private static readonly Vector2 Origin = new(16, 16);
    private Vector2 _cameraPos = Origin;
    private const float CameraSpeed = 210f;

    private readonly RenderContext _context;
    private readonly GameState _state;
    private readonly Action<SunKey> _onSunSelected;
    private readonly Action? _onOpenSystem;
    private readonly SunCache _cache;
    private readonly GalaxySunCache _animatedSuns;
    private readonly ValueNoise2D _noise;
    private readonly Dictionary<Point, GalaxyTile> _tiles = new();
    private readonly Dictionary<Point, List<Vector2>> _spatial = new();
    private readonly GalaxyHud _hud;
    private readonly PixelGalaxyBackdrop _backdrop;
    private readonly RasterizerState _mapRasterizer = new() { ScissorTestEnable = true, CullMode = CullMode.None };
    private readonly List<GalaxyTile> _visibleTiles = new(160);
    private readonly List<Point> _frontier = new(160);
    private readonly List<VisibleSun> _visibleSuns = new(160);
    private bool _mapDirty = true;
    private Vector2 _visibleCamera = new(float.NaN);
    private int _visibleZoom = -1;
    private int _systemsCount;

    private Point? _hoverTile;
    private int _hoverId = -1;
    private Point? _hoverSector;
    private string? _hoverName;
    private Point _mouseLogical = new(-1, -1);
    private GalaxyHudAction _hoverAction;
    private bool _hasSelection;
    private Point _selectedTile;
    private int _selectedId = -1;
    private Vector2 _selectedWorld;
    private string? _selectedName;
    private string? _selectedClass;
    private PixelSunRenderer? _preview;
    private Color _accent = new(164, 175, 220);

    private bool _pointerCaptured;
    private bool _primaryCapture;
    private bool _dragging;
    private Point _pressPosition;
    private Vector2 _pressCamera;
    private KeyboardState _previousKeys;
    private bool _showDebug;
    private double _seconds;
    private double _lastStarClick = double.NegativeInfinity;
    private string? _notice;
    private double _noticeUntil;

    public GalaxyView(RenderContext context, GameState state, Action<SunKey> onSunSelected, Action? onOpenSystem = null)
    {
        _context = context;
        _state = state;
        _onSunSelected = onSunSelected;
        _onOpenSystem = onOpenSystem;
        _cache = new SunCache(context.GraphicsDevice);
        _animatedSuns = new GalaxySunCache(context.GraphicsDevice);
        _noise = new ValueNoise2D(WorldSeed) { Frequency = NoiseFreq };
        _hud = new GalaxyHud(context);
        _backdrop = new PixelGalaxyBackdrop(context.GraphicsDevice, context.ViewSize, WorldSeed);
        GenerateInitialGrid();
        RebuildVisibleMap();
    }

    public ViewMode Mode => ViewMode.Galaxy;

    public void Update(GameTime gameTime, MouseState mouse, MouseState previousMouse)
    {
        _seconds = gameTime.TotalGameTime.TotalSeconds;
        _mouseLogical = _context.ScreenToLogical(mouse.Position);
        var keys = Keyboard.GetState();
        var dt = Math.Clamp((float)gameTime.ElapsedGameTime.TotalSeconds, 0, 0.1f);
        if (Pressed(keys, Keys.F3)) _showDebug = !_showDebug;
        if (Pressed(keys, Keys.Home)) GoHome();
        if (Pressed(keys, Keys.Space)) FocusSelection();
        if (Pressed(keys, Keys.Enter) && _hasSelection) _onOpenSystem?.Invoke();

        var inMap = _hud.MapBounds.Contains(_mouseLogical);
        var primaryPressed = mouse.LeftButton == ButtonState.Pressed && previousMouse.LeftButton == ButtonState.Released;
        var secondaryPressed = (mouse.MiddleButton == ButtonState.Pressed && previousMouse.MiddleButton == ButtonState.Released)
            || (mouse.RightButton == ButtonState.Pressed && previousMouse.RightButton == ButtonState.Released);
        _hoverAction = _hud.HitTest(_mouseLogical);
        if (!_pointerCaptured && primaryPressed && !inMap)
            ActivateHud(_hoverAction);
        if (!_pointerCaptured && inMap && (primaryPressed || secondaryPressed))
        {
            _pointerCaptured = true;
            _primaryCapture = primaryPressed;
            _dragging = false;
            _pressPosition = _mouseLogical;
            _pressCamera = _cameraPos;
        }
        if (_pointerCaptured)
        {
            var held = _primaryCapture ? mouse.LeftButton == ButtonState.Pressed
                : mouse.MiddleButton == ButtonState.Pressed || mouse.RightButton == ButtonState.Pressed;
            if (_mouseLogical.X >= 0)
            {
                var delta = _mouseLogical.ToVector2() - _pressPosition.ToVector2();
                if (delta.LengthSquared() >= 9) _dragging = true;
                if (_dragging) _cameraPos = _pressCamera - delta / CurrentZoom;
            }
            if (!held)
            {
                if (_primaryCapture && !_dragging && inMap) ClickMap(_mouseLogical);
                _pointerCaptured = false;
                _dragging = false;
            }
        }
        else
        {
            PanWithKeys(keys, dt);
            if (inMap && mouse.ScrollWheelValue != previousMouse.ScrollWheelValue)
            {
                var steps = Math.Sign(mouse.ScrollWheelValue - previousMouse.ScrollWheelValue);
                ChangeZoom(steps, _mouseLogical);
            }
        }
        _cameraPos = Vector2.Clamp(_cameraPos, new Vector2(-1000000), new Vector2(1000000));
        RebuildVisibleMap();
        UpdateHover(_mouseLogical);
        foreach (var sun in _visibleSuns)
            sun.AnimatedRenderer?.Update(_seconds * SolarAnimationSpeed);
        _preview?.Update(_seconds * SolarAnimationSpeed);
        _backdrop.Update(_seconds, _cameraPos, CurrentZoom, _accent);
        _previousKeys = keys;
    }

    private bool Pressed(KeyboardState keys, Keys key) => keys.IsKeyDown(key) && !_previousKeys.IsKeyDown(key);

    private void PanWithKeys(KeyboardState keys, float dt)
    {
        var direction = Vector2.Zero;
        if (keys.IsKeyDown(Keys.Left) || keys.IsKeyDown(Keys.A) || keys.IsKeyDown(Keys.Q)) direction.X -= 1;
        if (keys.IsKeyDown(Keys.Right) || keys.IsKeyDown(Keys.D)) direction.X += 1;
        if (keys.IsKeyDown(Keys.Up) || keys.IsKeyDown(Keys.W) || keys.IsKeyDown(Keys.Z)) direction.Y -= 1;
        if (keys.IsKeyDown(Keys.Down) || keys.IsKeyDown(Keys.S)) direction.Y += 1;
        if (direction == Vector2.Zero) return;
        direction.Normalize();
        var speed = keys.IsKeyDown(Keys.LeftShift) || keys.IsKeyDown(Keys.RightShift) ? 1.8f : 1f;
        _cameraPos += direction * (CameraSpeed * speed * dt / CurrentZoom);
    }

    private void ActivateHud(GalaxyHudAction action)
    {
        switch (action)
        {
            case GalaxyHudAction.ZoomOut: ChangeZoom(-1, _hud.MapBounds.Center); break;
            case GalaxyHudAction.ZoomIn: ChangeZoom(1, _hud.MapBounds.Center); break;
            case GalaxyHudAction.Home: GoHome(); break;
            case GalaxyHudAction.FocusSelection: if (_hasSelection) FocusSelection(); break;
            case GalaxyHudAction.OpenSystem: if (_hasSelection) _onOpenSystem?.Invoke(); break;
        }
    }

    private void ChangeZoom(int step, Point anchor)
    {
        var next = Math.Clamp(_currentZoomIndex + step, 0, _zoomLevels.Length - 1);
        if (next == _currentZoomIndex) return;
        var world = ScreenToWorld(anchor);
        _currentZoomIndex = next;
        _cameraPos += world - ScreenToWorld(anchor);
    }

    private void GoHome()
    {
        _cameraPos = Origin;
        _currentZoomIndex = 1;
        _pointerCaptured = false;
        _dragging = false;
    }

    private void FocusSelection()
    {
        _cameraPos = _hasSelection ? _selectedWorld : Origin;
        _pointerCaptured = false;
        _dragging = false;
    }

    private void UpdateHover(Point position)
    {
        _hoverTile = null;
        _hoverId = -1;
        _hoverSector = null;
        _hoverName = null;
        if (_dragging || !_hud.MapBounds.Contains(position)) return;
        var hit = FindSun(position);
        if (hit >= 0)
        {
            var sun = _visibleSuns[hit];
            _hoverTile = sun.Tile;
            _hoverId = sun.Index;
            _hoverName = sun.Name;
        }
        else _hoverSector = WorldToTile(ScreenToWorld(position));
    }

    private int FindSun(Point position)
    {
        var distance = float.PositiveInfinity;
        var closest = -1;
        for (var i = 0; i < _visibleSuns.Count; i++)
        {
            var sun = _visibleSuns[i];
            var radius = Math.Max(6, sun.Diameter * 0.5f + 2);
            var candidate = Vector2.DistanceSquared(position.ToVector2(), sun.Screen);
            if (candidate > radius * radius || candidate >= distance) continue;
            distance = candidate;
            closest = i;
        }
        return closest;
    }

    private void ClickMap(Point position)
    {
        RebuildVisibleMap();
        var hit = FindSun(position);
        if (hit >= 0)
        {
            var sun = _visibleSuns[hit];
            var doubleClick = _hasSelection && _selectedTile == sun.Tile && _selectedId == sun.Index && _seconds - _lastStarClick < 0.34;
            SelectSun(sun);
            _lastStarClick = _seconds;
            if (doubleClick) _onOpenSystem?.Invoke();
            return;
        }
        _lastStarClick = double.NegativeInfinity;
        var sector = WorldToTile(ScreenToWorld(position));
        if (!_tiles.ContainsKey(sector) && !IsAdjacentToGenerated(sector))
        {
            ShowNotice("Explorez depuis le bord de la carte.");
            return;
        }
        var before = _tiles.Count;
        GenerateNeighbors(sector, DiscoverColor);
        if (_tiles.Count > before) ShowNotice("De nouveaux secteurs sont visibles.");
        else ShowNotice("Les secteurs voisins sont déjà visibles.");
    }

    private void SelectSun(VisibleSun sun)
    {
        var changed = !_hasSelection || _selectedTile != sun.Tile || _selectedId != sun.Index;
        _hasSelection = true;
        _selectedTile = sun.Tile;
        _selectedId = sun.Index;
        _selectedWorld = sun.World;
        _selectedName = sun.Name;
        _selectedClass = sun.ClassId switch
        {
            0 => "Étoile corail",
            1 or 2 => "Étoile dorée",
            3 or 4 => "Étoile jade",
            _ => "Étoile azur"
        };
        var key = new SunKey(sun.Seed, sun.ClassId, 0, SunSizeFromSeed(sun.Seed), 4);
        if (changed)
        {
            _preview?.Dispose();
            _preview = new PixelSunRenderer(_context.GraphicsDevice, key, 40, SunRenderSettings.GalaxyCellSize);
            _preview.Update(_seconds * SolarAnimationSpeed);
            _accent = _preview.LightColor;
        }
        _onSunSelected(key);
        _notice = null;
    }

    private void ShowNotice(string notice)
    {
        _notice = notice;
        _noticeUntil = _seconds + 3;
    }

    private void RebuildVisibleMap()
    {
        if (!_mapDirty && _cameraPos == _visibleCamera && _visibleZoom == _currentZoomIndex) return;
        _visibleCamera = _cameraPos;
        _visibleZoom = _currentZoomIndex;
        _mapDirty = false;
        _visibleTiles.Clear();
        _visibleSuns.Clear();
        _frontier.Clear();
        var bounds = _hud.MapBounds;
        var first = WorldToTile(ScreenToWorld(new Point(bounds.Left, bounds.Top)));
        var last = WorldToTile(ScreenToWorld(new Point(bounds.Right, bounds.Bottom)));
        // Original chart dimensions: one shared diameter and pixel grid per zoom.
        var diameter = (int)(Lod0Size * CurrentZoom);
        var margin = diameter / 2 + (CurrentZoom >= SolarEffectsMinZoom ? 16 : 6);
        var extendedBounds = bounds;
        extendedBounds.Inflate(margin, margin);
        for (var y = first.Y - 1; y <= last.Y + 1; y++)
        for (var x = first.X - 1; x <= last.X + 1; x++)
        {
            var coordinate = new Point(x, y);
            if (!_tiles.TryGetValue(coordinate, out var tile))
            {
                if (IsAdjacentToGenerated(coordinate)) _frontier.Add(coordinate);
                continue;
            }
            _visibleTiles.Add(tile);
            for (var i = 0; i < tile.SunsLocal.Count; i++)
            {
                var world = tile.GetSunWorldPos(i);
                var screen = WorldToScreen(world);
                if (!extendedBounds.Contains(screen.ToPoint())) continue;
                var seed = SeedFromPoint(world);
                var classId = ClassFromSeed(seed);
                var size = SunSizeFromSeed(seed);
                SunTextures? texture = null;
                PixelSunRenderer? animated = null;
                if (CurrentZoom >= SolarEffectsMinZoom)
                {
                    var key = new SunKey(seed, classId, 0, size, 4);
                    animated = _animatedSuns.GetOrCreate(key, diameter);
                    // Absolute time also keeps newly visible/cached stars in phase.
                    animated.Update(_seconds * SolarAnimationSpeed);
                }
                else
                    texture = _cache.GetOrBake(_currentZoomIndex, seed, classId, diameter, LodSteps, SunRenderSettings.GalaxyCellSize);
                _visibleSuns.Add(new VisibleSun(tile.Coords, i, world, screen, seed, classId, diameter, texture, animated,
                    StarNames[(int)((uint)seed % StarNames.Length)] + "-" + ((uint)seed % 90 + 10)));
            }
        }
    }

    private Vector2 WorldToScreen(Vector2 position)
    {
        var center = _hud.MapBounds.Center.ToVector2();
        var screen = (position - _cameraPos) * CurrentZoom + center;
        return new Vector2(MathF.Round(screen.X), MathF.Round(screen.Y));
    }

    private Vector2 ScreenToWorld(Point position) =>
        (position.ToVector2() - _hud.MapBounds.Center.ToVector2()) / CurrentZoom + _cameraPos;

    private Matrix BuildCameraMatrix(Point viewSize) =>
        Matrix.CreateTranslation(new Vector3(-_cameraPos, 0)) * Matrix.CreateScale(CurrentZoom)
        * Matrix.CreateTranslation(new Vector3(_hud.MapBounds.Center.ToVector2(), 0));

    public void Draw(GameTime gameTime, RenderContext context)
    {
        RebuildVisibleMap();
        var sb = context.SpriteBatch;
        sb.Begin(samplerState: SamplerState.PointClamp);
        _backdrop.Draw(sb, context.Pixel);
        sb.End();

        var previousScissor = context.GraphicsDevice.ScissorRectangle;
        context.GraphicsDevice.ScissorRectangle = _hud.MapBounds;
        sb.Begin(samplerState: SamplerState.PointClamp, rasterizerState: _mapRasterizer);
        DrawMap(sb);
        sb.End();
        context.GraphicsDevice.ScissorRectangle = previousScissor;

        sb.Begin(samplerState: SamplerState.PointClamp);
        var hint = _seconds < _noticeUntil ? _notice : _dragging ? "Déplacement de la carte"
            : _hoverSector.HasValue && !_tiles.ContainsKey(_hoverSector.Value) && IsAdjacentToGenerated(_hoverSector.Value)
                ? "Cliquer sur + pour explorer" : null;
        _hud.Draw(sb, new GalaxyHudState(WorldToTile(_cameraPos), _systemsCount, _tiles.Count, (int)CurrentZoom,
            _selectedName, _selectedClass, _hasSelection ? _selectedTile : null, _hasSelection, _hoverAction, hint));
        if (_preview != null)
            _preview.Draw(sb, context.Pixel, _hud.PreviewBounds.Center.ToVector2());
        if (_showDebug) DrawDebug(sb);
        sb.End();
    }

    private void DrawMap(SpriteBatch sb)
    {
        foreach (var tile in _visibleTiles)
        {
            var rectangle = SectorRectangle(tile.Coords);
            if (_showDebug) sb.Draw(_context.Pixel, rectangle, tile.BaseColor * 0.14f);
            // Tiny chart intersections leave the space between stars open.
            DrawCorners(sb, rectangle, new Color(89, 113, 157) * 0.27f, 2, 1);
            if (!_tiles.ContainsKey(new Point(tile.Coords.X - 1, tile.Coords.Y))) DashedLine(sb, new Point(rectangle.Left, rectangle.Top), new Point(rectangle.Left, rectangle.Bottom), new Color(117, 143, 186) * 0.3f);
            if (!_tiles.ContainsKey(new Point(tile.Coords.X + 1, tile.Coords.Y))) DashedLine(sb, new Point(rectangle.Right, rectangle.Top), new Point(rectangle.Right, rectangle.Bottom), new Color(117, 143, 186) * 0.3f);
            if (!_tiles.ContainsKey(new Point(tile.Coords.X, tile.Coords.Y - 1))) DashedLine(sb, new Point(rectangle.Left, rectangle.Top), new Point(rectangle.Right, rectangle.Top), new Color(117, 143, 186) * 0.3f);
            if (!_tiles.ContainsKey(new Point(tile.Coords.X, tile.Coords.Y + 1))) DashedLine(sb, new Point(rectangle.Left, rectangle.Bottom), new Point(rectangle.Right, rectangle.Bottom), new Color(117, 143, 186) * 0.3f);
        }
        foreach (var sector in _frontier)
        {
            var rectangle = SectorRectangle(sector);
            var hover = _hoverSector == sector;
            var color = hover ? new Color(153, 220, 208) : new Color(88, 122, 151) * 0.55f;
            if (hover) sb.Draw(_context.Pixel, rectangle, new Color(55, 93, 115) * 0.2f);
            DrawCorners(sb, rectangle, color * (hover ? 0.65f : 0.3f), 5, 1);
            var center = rectangle.Center;
            sb.Draw(_context.Pixel, new Rectangle(center.X - 3, center.Y, 7, 1), color);
            sb.Draw(_context.Pixel, new Rectangle(center.X, center.Y - 3, 1, 7), color);
        }

        foreach (var sun in _visibleSuns)
        {
            var diameter = sun.Diameter;
            var rectangle = new Rectangle((int)sun.Screen.X - diameter / 2, (int)sun.Screen.Y - diameter / 2, diameter, diameter);
            if (sun.AnimatedRenderer != null)
                sun.AnimatedRenderer.Draw(sb, _context.Pixel, sun.Screen);
            else
            {
                var breathing = MathF.Floor((MathF.Sin((float)(_seconds * SolarAnimationSpeed * 0.65) + (sun.Seed & 255)) + 1) * 1.5f);
                var tint = Color.White * (0.94f + breathing * 0.02f);
                sb.Draw(sun.Texture!.Albedo, rectangle, tint);
            }
            var selected = _hasSelection && _selectedTile == sun.Tile && _selectedId == sun.Index;
            var hover = _hoverTile == sun.Tile && _hoverId == sun.Index;
            if (!selected && !hover) continue;
            rectangle.Inflate(sun.AnimatedRenderer != null ? 12 : 4, sun.AnimatedRenderer != null ? 12 : 4);
            DrawCorners(sb, rectangle, selected ? new Color(159, 227, 205) : new Color(246, 208, 161), 4, 1);
            if (selected)
                sb.Draw(_context.Pixel, new Rectangle(rectangle.Center.X - 1, rectangle.Bottom + 3, 3, 2), new Color(159, 227, 205));
        }
        if (_hoverName != null && !_dragging) DrawHoverLabel(sb);
        if (_hasSelection) DrawSelectionBearing(sb);
    }

    private Rectangle SectorRectangle(Point sector)
    {
        var origin = WorldToScreen(new Vector2(sector.X * TileSize, sector.Y * TileSize));
        return new Rectangle((int)origin.X, (int)origin.Y, (int)(TileSize * CurrentZoom), (int)(TileSize * CurrentZoom));
    }

    private void DrawHoverLabel(SpriteBatch sb)
    {
        var index = -1;
        for (var i = 0; i < _visibleSuns.Count; i++)
            if (_visibleSuns[i].Tile == _hoverTile && _visibleSuns[i].Index == _hoverId) { index = i; break; }
        if (index < 0) return;
        var sun = _visibleSuns[index];
        var diameter = sun.Diameter;
        var size = _context.Font.MeasureString(_hoverName) * 0.5f;
        var x = Math.Clamp(sun.Screen.X - size.X / 2, _hud.MapBounds.Left + 4, _hud.MapBounds.Right - size.X - 4);
        var spacing = sun.AnimatedRenderer != null ? 18 : 10;
        var y = sun.Screen.Y + diameter / 2 + spacing;
        if (y + size.Y + 4 > _hud.MapBounds.Bottom) y = sun.Screen.Y - diameter / 2 - size.Y - spacing;
        var box = new Rectangle((int)x - 4, (int)y - 2, (int)size.X + 8, (int)size.Y + 4);
        sb.Draw(_context.Pixel, box, new Color(15, 23, 39) * 0.94f);
        sb.DrawString(_context.Font, _hoverName, new Vector2((int)x, (int)y), new Color(224, 229, 231), 0, Vector2.Zero, 0.5f, SpriteEffects.None, 0);
    }

    private void DrawSelectionBearing(SpriteBatch sb)
    {
        var target = WorldToScreen(_selectedWorld);
        var bounds = _hud.MapBounds;
        if (bounds.Contains(target.ToPoint())) return;
        var center = bounds.Center.ToVector2();
        var direction = target - center;
        var half = new Vector2(bounds.Width / 2f - 10, bounds.Height / 2f - 10);
        var ratio = MathF.Max(MathF.Abs(direction.X) / half.X, MathF.Abs(direction.Y) / half.Y);
        var edge = center + direction / ratio;
        var horizontal = MathF.Abs(direction.X) / half.X >= MathF.Abs(direction.Y) / half.Y;
        var sign = Math.Sign(horizontal ? direction.X : direction.Y);
        for (var i = 0; i < 3; i++)
        {
            var rect = horizontal
                ? new Rectangle((int)edge.X - sign * i, (int)edge.Y - i, 1, i * 2 + 1)
                : new Rectangle((int)edge.X - i, (int)edge.Y - sign * i, i * 2 + 1, 1);
            sb.Draw(_context.Pixel, rect, new Color(159, 227, 205));
        }
    }

    private void DrawCorners(SpriteBatch sb, Rectangle rectangle, Color color, int length, int thickness)
    {
        sb.Draw(_context.Pixel, new Rectangle(rectangle.Left, rectangle.Top, length, thickness), color);
        sb.Draw(_context.Pixel, new Rectangle(rectangle.Right - length, rectangle.Top, length, thickness), color);
        sb.Draw(_context.Pixel, new Rectangle(rectangle.Left, rectangle.Bottom - thickness, length, thickness), color);
        sb.Draw(_context.Pixel, new Rectangle(rectangle.Right - length, rectangle.Bottom - thickness, length, thickness), color);
        sb.Draw(_context.Pixel, new Rectangle(rectangle.Left, rectangle.Top, thickness, length), color);
        sb.Draw(_context.Pixel, new Rectangle(rectangle.Right - thickness, rectangle.Top, thickness, length), color);
        sb.Draw(_context.Pixel, new Rectangle(rectangle.Left, rectangle.Bottom - length, thickness, length), color);
        sb.Draw(_context.Pixel, new Rectangle(rectangle.Right - thickness, rectangle.Bottom - length, thickness, length), color);
    }

    private void DashedLine(SpriteBatch sb, Point start, Point end, Color color)
    {
        var horizontal = start.Y == end.Y;
        var length = horizontal ? end.X - start.X : end.Y - start.Y;
        for (var i = 2; i < length - 2; i += 8)
            sb.Draw(_context.Pixel, new Rectangle(start.X + (horizontal ? i : 0), start.Y + (horizontal ? 0 : i),
                horizontal ? 3 : 1, horizontal ? 1 : 3), color);
    }

    private void DrawDebug(SpriteBatch sb)
    {
        var rect = new Rectangle(_hud.MapBounds.X + 6, _hud.MapBounds.Y + 6, 250, 46);
        sb.Draw(_context.Pixel, rect, new Color(9, 14, 25) * 0.96f);
        var text = FormattableString.Invariant($"Cam {_cameraPos.X:0.0}, {_cameraPos.Y:0.0}  /  x{CurrentZoom:0}\nSecteurs {_tiles.Count}  /  systèmes {_systemsCount}\nCache {_cache.Hits} / {_cache.Misses}  -  F3");
        sb.DrawString(_context.Font, text, new Vector2(rect.X + 6, rect.Y + 5), new Color(159, 180, 201), 0, Vector2.Zero, 0.45f, SpriteEffects.None, 0);
    }

    public void Dispose()
    {
        _preview?.Dispose();
        _cache.Dispose();
        _animatedSuns.Dispose();
        _backdrop.Dispose();
        _mapRasterizer.Dispose();
    }

    private readonly record struct VisibleSun(Point Tile, int Index, Vector2 World, Vector2 Screen, int Seed,
        int ClassId, int Diameter, SunTextures? Texture, PixelSunRenderer? AnimatedRenderer, string Name);
}
