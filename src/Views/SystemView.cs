using System;
using System.Collections.Generic;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;
using MonogameAS.Extensions;
using MonogameAS.Galaxy;
using MonogameAS.Logging;
using MonogameAS.Planet;
using MonogameAS.Rendering;
using MonogameAS.State;
using MonogameAS.Systems;

namespace MonogameAS.Views;

/// <summary>
/// Vue système : soleil + multiples planètes sur orbites elliptiques (déterministe par seed).
/// Les miniatures utilisent le même atlas sphérique que la vue planète.
/// </summary>
public class SystemView : IView, IDisposable
{
    private readonly RenderContext _context;
    private readonly GameState _state;
    private readonly SystemProvider _systemProvider;
    private readonly PlanetParams _basePlanetParams;
    private readonly PlanetPaletteType _basePlanetPalette;
    private SystemParams _systemParams;
    private bool _systemParamsDirty;

    private PixelSunRenderer? _sun;
    private PixelSpaceBackdrop? _backdrop;
    private Texture2D? _orbits;
    private float _cachedOrbitThickness = float.NaN;
    private float _cachedOrbitAlpha = float.NaN;
    private bool _showDebug;
    private bool _f3WasDown;
    private int? _hoveredSeed;
    private SunKey _cachedSun = SunKey.Default;
    private SystemData? _system;
    private int _cachedSystemSeed = int.MinValue;
    private double _time;
    private readonly List<(PlanetOrbital orbital, Vector2 pos, float radius)> _planetScreen = new();
    private int? _selectedSeed = null;

    private readonly Dictionary<int, SystemPlanetSprite> _planetCache = new();
    private readonly List<DebugSlider> _systemSliders = new();
    private readonly List<DebugSlider> _orbitSliders = new();

    private const int SunSystemScale = 2; // ancien ratio système (sun.lua RATIO_PLANET_VIEW)
    private const int SunSystemMinTex = 32;
    private const int SunSystemMaxTex = 128;
    // One shared visible pixel grid for the sun and every planetary miniature.
    private const int SystemPlanetCellSize = SunRenderSettings.SystemCellSize;
    private const float SystemPlanetPixelFactor = 0.85f;
    private const int SystemPlanetMinTiles = 4;
    private const float DebugTextScale = 0.6f;
    private const int DebugPanelPadding = 4;
    private const int DebugPanelGap = 6;
    private const int DebugPanelTitleHeight = 12;
    private const int DebugSliderRowHeight = 16;
    private const int DebugSliderLabelWidth = 60;
    private const int DebugSliderValueWidth = 34;
    private const int DebugSliderTrackHeight = 4;
    private const int DebugSliderKnobWidth = 6;
    private const int DebugSliderKnobHeight = 10;

    public SystemView(RenderContext context, GameState state, PlanetProvider planetProvider, SystemProvider systemProvider, SystemParams systemParams)
    {
        _context = context;
        _state = state;
        _systemProvider = systemProvider;
        _basePlanetParams = state.PlanetKey.Params;
        _basePlanetPalette = state.PlanetKey.Palette;
        _systemParams = systemParams;
        BuildDebugSliders();
        RefreshSun();
    }

    public ViewMode Mode => ViewMode.System;

    public void Update(GameTime gameTime, MouseState mouse, MouseState previousMouse)
    {
        _time = gameTime.TotalGameTime.TotalSeconds;

        if (_sun == null || _cachedSun != _state.SunKey)
            RefreshSun();
        _sun?.Update(_time);
        _backdrop?.Update(_time, _sun?.LightColor ?? Color.White, _context.ViewSize.ToVector2() * 0.5f);

        var f3Down = Keyboard.GetState().IsKeyDown(Keys.F3);
        if (f3Down && !_f3WasDown) _showDebug = !_showDebug;
        _f3WasDown = f3Down;

        var logicalPos = _context.ScreenToLogical(mouse.Position);
        var leftDown = mouse.LeftButton == ButtonState.Pressed;
        var leftPrev = previousMouse.LeftButton == ButtonState.Pressed;
        var uiConsumed = _showDebug && UpdateDebugUi(logicalPos, leftDown, leftPrev);
        ApplySystemParamsIfDirty();

        if (_system == null || _cachedSystemSeed != _state.SystemSeed || _system.Sun != _state.SunKey)
        {
            _system = _systemProvider.GetOrGenerate(
                _state.SystemSeed,
                _state.SunKey,
                _systemParams,
                _basePlanetParams,
                _basePlanetPalette);
            _cachedSystemSeed = _state.SystemSeed;
            ClearPlanetCache();
            _orbits?.Dispose();
            _orbits = null;
            Logger.Info($"[SystemView] System regen seed={_cachedSystemSeed} planets={_system.Planets.Count}");
        }

        // Pré-calc positions pour rendu + clic
        _planetScreen.Clear();
        if (_system != null)
        {
            var center = _context.ViewSize.ToVector2() * 0.5f;
            var maxA = 1f;
            foreach (var p in _system.Planets)
                maxA = MathF.Max(maxA, p.SemiMajor);
            var maxWidth = _context.ViewSize.X * 0.45f;

            foreach (var p in _system.Planets)
            {
                // Terrain edits belong to the selected world, never to every
                // planet subsequently generated in another system.
                p.PlanetKey = _state.RestorePlanet(p.PlanetKey);
                var rx = (p.SemiMajor / maxA) * maxWidth;
                var ry = OrbitMinor(p, rx);
                var angle = p.Angle0 + (float)(_time * p.AngularSpeed * 0.22);
                var pos = center + new Vector2(MathF.Cos(angle) * rx, MathF.Sin(angle) * ry);
                pos = new Vector2(MathF.Round(pos.X), MathF.Round(pos.Y));

                var tex = GetPlanetTexture(_context, p, center - pos);
                var radius = MathF.Max(tex.Width, tex.Height) * 0.5f * SystemPlanetCellSize;
                _planetScreen.Add((p, pos, radius));
            }
            _planetScreen.Sort(static (a, b) => a.pos.Y.CompareTo(b.pos.Y));
            RefreshOrbits(center, _system);
        }

        _hoveredSeed = null;
        if (!uiConsumed && logicalPos.X >= 0)
        {
            for (var i = _planetScreen.Count - 1; i >= 0; i--)
            {
                var entry = _planetScreen[i];
                if (IsHiddenBySun(entry.pos, entry.radius)) continue;
                if (Vector2.Distance(logicalPos.ToVector2(), entry.pos) <= MathF.Max(6f, entry.radius + 2))
                {
                    _hoveredSeed = entry.orbital.PlanetKey.Seed;
                    break;
                }
            }
        }

        // Sélection au clic (debug): met à jour PlanetKey, pas de changement de vue automatique
        if (!uiConsumed && logicalPos.X >= 0 && leftDown && !leftPrev)
        {
            foreach (var entry in _planetScreen)
            {
                if (_hoveredSeed == entry.orbital.PlanetKey.Seed)
                {
                    _state.SetPlanetKey(entry.orbital.PlanetKey);
                    _selectedSeed = entry.orbital.PlanetKey.Seed;
                    Logger.Info($"[SystemView] Planet selected seed={entry.orbital.PlanetKey.Seed}");
                    break;
                }
            }
        }
    }

    public void Draw(GameTime gameTime, RenderContext context)
    {
        var sb = context.SpriteBatch;
        sb.Begin(samplerState: SamplerState.PointClamp);

        _backdrop?.Draw(sb, context.Pixel);

        var center = context.ViewSize.ToVector2() * 0.5f;

        if (_orbits != null) sb.Draw(_orbits, Vector2.Zero, Color.White);
        DrawPlanets(sb, center, behind: true);
        _sun?.Draw(sb, context.Pixel, center);
        DrawPlanets(sb, center, behind: false);

        // HUD label
        const string label = "Vue systeme";
        var size = context.Font.MeasureString(label);
        var position = new Vector2(context.ViewSize.X - size.X - 12, 12);
        sb.DrawString(context.Font, label, position, new Color(203, 216, 230));

        if (_showDebug) DrawDebugPanel(sb, context.ViewSize);
        else
        {
            sb.DrawString(context.Font, "F3 : reglages", new Vector2(10, context.ViewSize.Y - 17), new Color(120, 136, 158), 0f, Vector2.Zero, 0.6f, SpriteEffects.None, 0f);
        }

        sb.End();
    }

    public void Dispose()
    {
        _sun?.Dispose();
        _backdrop?.Dispose();
        _orbits?.Dispose();
        ClearPlanetCache();
    }

    private void RefreshSun()
    {
        _cachedSun = _state.SunKey;
        var key = _cachedSun;
        var systemRadius = Math.Max(1, key.Size) * SunSystemScale;
        var texSize = systemRadius * 2;
        texSize = SnapToCell(texSize, SunRenderSettings.SystemCellSize);
        texSize = Math.Clamp(texSize, SunSystemMinTex, SunSystemMaxTex);
        _sun?.Dispose();
        _sun = new PixelSunRenderer(_context.GraphicsDevice, key, texSize, SunRenderSettings.SystemCellSize);
        _orbits?.Dispose();
        _orbits = null;
        _backdrop?.Dispose();
        _backdrop = new PixelSpaceBackdrop(_context.GraphicsDevice, _context.ViewSize, key.Seed);
        _backdrop.Update(_time, _sun.LightColor, _context.ViewSize.ToVector2() * 0.5f);
    }

    private void ClearPlanetCache()
    {
        foreach (var sprite in _planetCache.Values) sprite.Texture.Dispose();
        _planetCache.Clear();
    }

    private void RefreshOrbits(Vector2 center, SystemData sys)
    {
        var thickness = SystemOrbitRenderSettings.OrbitThickness;
        var alpha = Math.Clamp(SystemOrbitRenderSettings.OrbitAlpha, 0f, 1f);
        if (_orbits != null && thickness == _cachedOrbitThickness && alpha == _cachedOrbitAlpha)
            return;
        _cachedOrbitThickness = thickness;
        _cachedOrbitAlpha = alpha;
        var width = _context.ViewSize.X;
        var height = _context.ViewSize.Y;
        var pixels = new Color[width * height];
        var orbitColor = Color.Lerp(new Color(152, 169, 192), _sun?.LightColor ?? Color.White, 0.12f);
        var maxA = 1f;
        foreach (var p in sys.Planets)
            maxA = MathF.Max(maxA, p.SemiMajor);

        var maxWidth = _context.ViewSize.X * 0.45f;
        foreach (var p in sys.Planets)
        {
            var rx = (p.SemiMajor / maxA) * maxWidth;
            var ry = OrbitMinor(p, rx);
            var steps = Math.Clamp((int)MathF.Ceiling(MathF.Tau * rx * 1.4f), 64, 3000);
            for (var i = 0; i < steps; i++)
            {
                var angle = MathF.Tau * i / steps;
                var sine = MathF.Sin(angle);
                var x = (int)MathF.Round(center.X + MathF.Cos(angle) * rx);
                var y = (int)MathF.Round(center.Y + sine * ry);
                var opacity = alpha * Math.Clamp(thickness, 0f, 1f) * (sine < 0 ? 0.65f : 1f);
                if (x < 0 || y < 0 || x >= width || y >= height) continue;
                pixels[y * width + x] = orbitColor * opacity;
                if (thickness > 1f && y + 1 < height)
                    pixels[(y + 1) * width + x] = orbitColor * (opacity * (thickness - 1f));
            }
        }
        _orbits ??= new Texture2D(_context.GraphicsDevice, width, height);
        _orbits.SetData(pixels);
    }

    private static float OrbitMinor(PlanetOrbital planet, float major) =>
        major * 0.39f * Math.Clamp(planet.SemiMinor / Math.Max(1, planet.SemiMajor), 0.4f, 1f);

    private bool IsHiddenBySun(Vector2 position, float radius)
    {
        var center = _context.ViewSize.ToVector2() * 0.5f;
        var sunRadius = Math.Clamp(Math.Max(1, _cachedSun.Size) * SunSystemScale * 2,
            SunSystemMinTex, SunSystemMaxTex) * 0.5f;
        return position.Y < center.Y && Vector2.Distance(position, center) + radius < sunRadius;
    }

    private void BuildDebugSliders()
    {
        _systemSliders.Clear();
        _orbitSliders.Clear();

        _systemSliders.Add(DebugSlider.Float("MinP", 0f, 12f, () => _systemParams.MinPlanets, v => UpdateSystemParams(p => p with { MinPlanets = RoundToInt(v) }), isInt: true));
        _systemSliders.Add(DebugSlider.Float("MaxP", 1f, 16f, () => _systemParams.MaxPlanets, v => UpdateSystemParams(p => p with { MaxPlanets = RoundToInt(v) }), isInt: true));
        _systemSliders.Add(DebugSlider.Float("SemiM", 20f, 200f, () => _systemParams.SemiMajorMin, v => UpdateSystemParams(p => p with { SemiMajorMin = v })));
        _systemSliders.Add(DebugSlider.Float("Space", 20f, 140f, () => _systemParams.OrbitalSpacing, v => UpdateSystemParams(p => p with { OrbitalSpacing = v })));
        _systemSliders.Add(DebugSlider.Float("EccMin", 0f, 0.6f, () => _systemParams.EccentricityMin, v => UpdateSystemParams(p => p with { EccentricityMin = v })));
        _systemSliders.Add(DebugSlider.Float("EccMax", 0f, 0.9f, () => _systemParams.EccentricityMax, v => UpdateSystemParams(p => p with { EccentricityMax = v })));
        _systemSliders.Add(DebugSlider.Float("AngMin", 0f, 0.3f, () => _systemParams.AngularSpeedMin, v => UpdateSystemParams(p => p with { AngularSpeedMin = v })));
        _systemSliders.Add(DebugSlider.Float("AngMax", 0f, 0.6f, () => _systemParams.AngularSpeedMax, v => UpdateSystemParams(p => p with { AngularSpeedMax = v })));
        _systemSliders.Add(DebugSlider.Float("RadMin", 4f, 40f, () => _systemParams.PlanetRadiusMin, v => UpdateSystemParams(p => p with { PlanetRadiusMin = v })));
        _systemSliders.Add(DebugSlider.Float("RadMax", 4f, 60f, () => _systemParams.PlanetRadiusMax, v => UpdateSystemParams(p => p with { PlanetRadiusMax = v })));
        _systemSliders.Add(DebugSlider.Float("Gap", 0f, 40f, () => _systemParams.CollisionGap, v => UpdateSystemParams(p => p with { CollisionGap = v })));

        _orbitSliders.Add(DebugSlider.Float("Epais", 0f, 2f, () => SystemOrbitRenderSettings.OrbitThickness, v => SystemOrbitRenderSettings.OrbitThickness = v));
        _orbitSliders.Add(DebugSlider.Float("Opac", 0f, 0.25f, () => SystemOrbitRenderSettings.OrbitAlpha, v => SystemOrbitRenderSettings.OrbitAlpha = v));
    }

    private void ApplySystemParamsIfDirty()
    {
        if (!_systemParamsDirty)
            return;

        _systemParamsDirty = false;
        _systemProvider.Clear();
        _system = null;
        _cachedSystemSeed = int.MinValue;
        ClearPlanetCache();
    }

    private void UpdateSystemParams(Func<SystemParams, SystemParams> mutator)
    {
        var next = SanitizeSystemParams(mutator(_systemParams));
        if (!next.Equals(_systemParams))
        {
            _systemParams = next;
            _systemParamsDirty = true;
        }
    }

    private static SystemParams SanitizeSystemParams(SystemParams p)
    {
        var minPlanets = Math.Max(0, p.MinPlanets);
        var maxPlanets = Math.Max(minPlanets, p.MaxPlanets);
        var semiMajorMin = Math.Max(1f, p.SemiMajorMin);
        var spacing = Math.Max(0f, p.OrbitalSpacing);
        var eccMin = Math.Clamp(p.EccentricityMin, 0f, 0.95f);
        var eccMax = Math.Clamp(p.EccentricityMax, eccMin, 0.95f);
        var angMin = Math.Max(0f, p.AngularSpeedMin);
        var angMax = Math.Max(angMin, p.AngularSpeedMax);
        var radiusMin = Math.Max(1f, p.PlanetRadiusMin);
        var radiusMax = Math.Max(radiusMin, p.PlanetRadiusMax);
        var gap = Math.Max(0f, p.CollisionGap);

        return p with
        {
            MinPlanets = minPlanets,
            MaxPlanets = maxPlanets,
            SemiMajorMin = semiMajorMin,
            OrbitalSpacing = spacing,
            EccentricityMin = eccMin,
            EccentricityMax = eccMax,
            AngularSpeedMin = angMin,
            AngularSpeedMax = angMax,
            PlanetRadiusMin = radiusMin,
            PlanetRadiusMax = radiusMax,
            CollisionGap = gap
        };
    }

    private static int RoundToInt(float v)
    {
        return (int)MathF.Round(v);
    }

    private bool UpdateDebugUi(Point mouse, bool leftDown, bool leftPrev)
    {
        GetDebugPanelRects(_context.ViewSize, out var systemPanel, out var orbitPanel);
        var overSystem = systemPanel.Contains(mouse);
        var overOrbit = orbitPanel.Contains(mouse);

        if (overSystem)
            UpdateSliderPanel(_systemSliders, systemPanel, mouse, leftDown, leftPrev, 2);
        if (overOrbit)
            UpdateSliderPanel(_orbitSliders, orbitPanel, mouse, leftDown, leftPrev, 1);

        return leftDown && (overSystem || overOrbit);
    }

    private void DrawDebugPanel(SpriteBatch sb, Point view)
    {
        GetDebugPanelRects(view, out var systemPanel, out var orbitPanel);
        var bg = new Color(0, 0, 0, 90);
        var outline = new Color(255, 255, 255, 18);

        sb.Draw(_context.Pixel, systemPanel, bg);
        DrawRectOutline(sb, _context.Pixel, systemPanel, outline);
        sb.DrawString(_context.Font, "Systeme", new Vector2(systemPanel.X + DebugPanelPadding, systemPanel.Y + 2), new Color(220, 220, 220, 200), 0f, Vector2.Zero, DebugTextScale, SpriteEffects.None, 0f);
        DrawSliderPanel(sb, _systemSliders, systemPanel, 2);

        sb.Draw(_context.Pixel, orbitPanel, bg);
        DrawRectOutline(sb, _context.Pixel, orbitPanel, outline);
        sb.DrawString(_context.Font, "Orbites", new Vector2(orbitPanel.X + DebugPanelPadding, orbitPanel.Y + 2), new Color(220, 220, 220, 200), 0f, Vector2.Zero, DebugTextScale, SpriteEffects.None, 0f);
        DrawSliderPanel(sb, _orbitSliders, orbitPanel, 1);
    }

    private void UpdateSliderPanel(List<DebugSlider> sliders, Rectangle panel, Point mouse, bool leftDown, bool leftPrev, int columns)
    {
        columns = Math.Max(1, columns);
        var rows = Math.Max(1, (int)MathF.Ceiling(sliders.Count / (float)columns));
        var colWidth = (panel.Width - DebugPanelPadding * 2 - DebugPanelGap) / columns;
        colWidth = Math.Max(1, colWidth);
        var startY = panel.Y + DebugPanelTitleHeight + DebugPanelPadding;

        for (var i = 0; i < sliders.Count; i++)
        {
            var col = i / rows;
            var row = i % rows;
            var x = panel.X + DebugPanelPadding + col * (colWidth + DebugPanelGap);
            var y = startY + row * DebugSliderRowHeight;
            var rowRect = new Rectangle(x, y, colWidth, DebugSliderRowHeight);
            var trackRect = DebugSlider.MakeTrackRect(rowRect, DebugSliderLabelWidth, DebugSliderValueWidth);
            sliders[i].Update(mouse, leftDown, leftPrev, trackRect);
        }
    }

    private void DrawSliderPanel(SpriteBatch sb, List<DebugSlider> sliders, Rectangle panel, int columns)
    {
        columns = Math.Max(1, columns);
        var rows = Math.Max(1, (int)MathF.Ceiling(sliders.Count / (float)columns));
        var colWidth = (panel.Width - DebugPanelPadding * 2 - DebugPanelGap) / columns;
        colWidth = Math.Max(1, colWidth);
        var startY = panel.Y + DebugPanelTitleHeight + DebugPanelPadding;

        for (var i = 0; i < sliders.Count; i++)
        {
            var col = i / rows;
            var row = i % rows;
            var x = panel.X + DebugPanelPadding + col * (colWidth + DebugPanelGap);
            var y = startY + row * DebugSliderRowHeight;
            var rowRect = new Rectangle(x, y, colWidth, DebugSliderRowHeight);
            sliders[i].Draw(sb, _context, rowRect);
        }
    }

    private static int GetPanelHeight(List<DebugSlider> sliders, int columns)
    {
        columns = Math.Max(1, columns);
        var rows = Math.Max(1, (int)MathF.Ceiling(sliders.Count / (float)columns));
        return DebugPanelTitleHeight + DebugPanelPadding * 2 + rows * DebugSliderRowHeight;
    }

    private void GetDebugPanelRects(Point view, out Rectangle systemPanel, out Rectangle orbitPanel)
    {
        var panelWidth = Math.Max(1, (view.X - DebugPanelGap * 3) / 2);
        var systemHeight = GetPanelHeight(_systemSliders, 2);
        var orbitHeight = GetPanelHeight(_orbitSliders, 1);
        var panelHeight = Math.Max(systemHeight, orbitHeight);
        var y = view.Y - panelHeight - DebugPanelGap;
        systemPanel = new Rectangle(DebugPanelGap, y, panelWidth, panelHeight);
        orbitPanel = new Rectangle(DebugPanelGap * 2 + panelWidth, y, panelWidth, panelHeight);
    }

    private void DrawPlanets(SpriteBatch sb, Vector2 center, bool behind)
    {
        foreach (var entry in _planetScreen)
        {
            if ((entry.pos.Y < center.Y) != behind) continue;
            var tex = _planetCache[entry.orbital.PlanetKey.Seed].Texture;
            var diameter = tex.Width * SystemPlanetCellSize;
            var rect = new Rectangle((int)entry.pos.X - diameter / 2, (int)entry.pos.Y - diameter / 2, diameter, diameter);
            sb.Draw(tex, rect, behind ? new Color(223, 229, 241) : Color.White);

            if (_selectedSeed == entry.orbital.PlanetKey.Seed || _hoveredSeed == entry.orbital.PlanetKey.Seed)
            {
                rect.Inflate(4, 4);
                var color = _selectedSeed == entry.orbital.PlanetKey.Seed ? new Color(139, 221, 210) : new Color(151, 169, 187);
                DrawSelectionCorners(sb, rect, color);
            }
        }
    }

    private Texture2D GetPlanetTexture(RenderContext context, PlanetOrbital orbital, Vector2 toSun)
    {
        if (!_planetCache.TryGetValue(orbital.PlanetKey.Seed, out var sprite) || sprite.Key != orbital.PlanetKey)
        {
            sprite?.Texture.Dispose();
            var desiredDiameter = orbital.RadiusLogical * SystemPlanetPixelFactor;
            var tiles = Math.Clamp((int)MathF.Floor(desiredDiameter / SystemPlanetCellSize), SystemPlanetMinTiles, 64);
            sprite = new SystemPlanetSprite(context.GraphicsDevice, orbital.PlanetKey, tiles);
            _planetCache[orbital.PlanetKey.Seed] = sprite;
        }
        sprite.Update(_time, toSun, _sun?.LightColor ?? Color.White);
        return sprite.Texture;
    }

    private void DrawSelectionCorners(SpriteBatch sb, Rectangle rect, Color color)
    {
        const int length = 3;
        sb.Draw(_context.Pixel, new Rectangle(rect.Left, rect.Top, length, 1), color);
        sb.Draw(_context.Pixel, new Rectangle(rect.Left, rect.Top, 1, length), color);
        sb.Draw(_context.Pixel, new Rectangle(rect.Right - length, rect.Top, length, 1), color);
        sb.Draw(_context.Pixel, new Rectangle(rect.Right - 1, rect.Top, 1, length), color);
        sb.Draw(_context.Pixel, new Rectangle(rect.Left, rect.Bottom - 1, length, 1), color);
        sb.Draw(_context.Pixel, new Rectangle(rect.Left, rect.Bottom - length, 1, length), color);
        sb.Draw(_context.Pixel, new Rectangle(rect.Right - length, rect.Bottom - 1, length, 1), color);
        sb.Draw(_context.Pixel, new Rectangle(rect.Right - 1, rect.Bottom - length, 1, length), color);
    }

    private static int SnapToCell(int size, int cell)
    {
        if (cell <= 0) return size;
        var usable = size - (size % cell);
        return Math.Max(cell, usable);
    }

    private static void DrawRectOutline(SpriteBatch sb, Texture2D pixel, Rectangle rect, Color color)
    {
        sb.Draw(pixel, new Rectangle(rect.X, rect.Y, rect.Width, 1), color);
        sb.Draw(pixel, new Rectangle(rect.X, rect.Y + rect.Height - 1, rect.Width, 1), color);
        sb.Draw(pixel, new Rectangle(rect.X, rect.Y, 1, rect.Height), color);
        sb.Draw(pixel, new Rectangle(rect.X + rect.Width - 1, rect.Y, 1, rect.Height), color);
    }

    /// <summary>Small sphere projections share the close view's permanent atlas.</summary>
    private sealed class SystemPlanetSprite
    {
        private readonly PlanetWorldMap _world;
        private readonly PlanetKey _key;
        private readonly Vector3[] _normals;
        private readonly Vector2[] _coordinates;
        private readonly Color[] _pixels;
        private readonly int _tiles;
        private long _lastTick = long.MinValue;

        public Texture2D Texture { get; }
        public PlanetKey Key => _key;

        public SystemPlanetSprite(GraphicsDevice device, PlanetKey key, int tiles)
        {
            _world = PlanetWorldMap.GetOrGenerate(key);
            _key = key;
            _tiles = tiles;
            _normals = new Vector3[tiles * tiles];
            _coordinates = new Vector2[tiles * tiles];
            _pixels = new Color[tiles * tiles];
            Texture = new Texture2D(device, tiles, tiles);
            for (var y = 0; y < tiles; y++)
            for (var x = 0; x < tiles; x++)
            {
                var nx = (x + 0.5f) * 2f / tiles - 1f;
                var ny = (y + 0.5f) * 2f / tiles - 1f;
                var square = nx * nx + ny * ny;
                if (square > 1f) continue;
                var nz = MathF.Sqrt(1f - square);
                _normals[y * tiles + x] = new Vector3(nx, -ny, nz);
                _coordinates[y * tiles + x] = new Vector2(MathF.Atan2(nx, nz), MathF.Asin(-ny));
            }
        }

        public void Update(double seconds, Vector2 toSun, Color sunlight)
        {
            var tick = (long)(seconds * 8);
            if (tick == _lastTick) return;
            _lastTick = tick;
            var light = toSun.LengthSquared() > 0 ? Vector2.Normalize(toSun) : -Vector2.UnitX;
            var direction = Vector3.Normalize(new Vector3(light.X, -light.Y, 0.38f));
            var rotation = (float)(seconds * MathF.Tau / 84);
            for (var y = 0; y < _tiles; y++)
            for (var x = 0; x < _tiles; x++)
            {
                var i = y * _tiles + x;
                var normal = _normals[i];
                if (normal == Vector3.Zero) continue;
                var coordinates = _coordinates[i];
                var longitude = coordinates.X + rotation;
                var terrain = _world.SampleCell(longitude, coordinates.Y).Terrain;
                var color = _world.SampleColor(longitude, coordinates.Y);
                var cloudLongitude = longitude + (float)seconds * 0.006f;
                var cosLatitude = MathF.Cos(coordinates.Y);
                var cloudPosition = new Vector3(MathF.Sin(cloudLongitude) * cosLatitude,
                    MathF.Sin(coordinates.Y), MathF.Cos(cloudLongitude) * cosLatitude);
                var clouds = SphereNoise.Fractal(cloudPosition * 4.2f, _key.Seed ^ 0x01ca713d, 2, 2.5f, 0.48f);
                if (clouds > _key.Params.CloudThreshold + 0.07f)
                    color = Color.Lerp(color, new Color(234, 241, 247), clouds > _key.Params.CloudThreshold + 0.17f ? 0.62f : 0.32f);
                color = PixelPlanetRenderer.ShadeTerrain(color, terrain, normal, direction, sunlight);
                var diffuse = MathF.Max(0, Vector3.Dot(normal, direction));
                if (normal.Z < 0.45f && diffuse > 0.2f)
                    color = Color.Lerp(color, _world.Palette.Atmosphere, 0.2f * _world.AtmosphereStrength);
                _pixels[i] = color;
            }
            Texture.SetData(_pixels);
        }
    }

    private sealed class DebugSlider
    {
        public string Label { get; }
        public float Min { get; }
        public float Max { get; }
        public bool IsInt { get; }
        private readonly Func<float> _getter;
        private readonly Action<float> _setter;
        private bool _dragging;

        private DebugSlider(string label, float min, float max, Func<float> getter, Action<float> setter, bool isInt)
        {
            Label = label;
            Min = min;
            Max = max;
            _getter = getter;
            _setter = setter;
            IsInt = isInt;
        }

        public static DebugSlider Float(string label, float min, float max, Func<float> getter, Action<float> setter, bool isInt = false)
        {
            return new DebugSlider(label, min, max, getter, setter, isInt);
        }

        public void Update(Point mouse, bool leftDown, bool leftPrev, Rectangle track)
        {
            var hovering = track.Contains(mouse);
            if (!leftDown)
                _dragging = false;

            if ((leftDown && !leftPrev && hovering) || (_dragging && leftDown))
            {
                _dragging = true;
                var t = track.Width <= 0 ? 0f : (mouse.X - track.X) / (float)track.Width;
                t = Math.Clamp(t, 0f, 1f);
                var value = Min + (Max - Min) * t;
                if (IsInt)
                    value = MathF.Round(value);
                _setter(value);
            }
        }

        public void Draw(SpriteBatch sb, RenderContext context, Rectangle row)
        {
            var track = MakeTrackRect(row, DebugSliderLabelWidth, DebugSliderValueWidth);
            var value = _getter();
            var t = Math.Abs(Max - Min) < 1e-6f ? 0f : (value - Min) / (Max - Min);
            t = Math.Clamp(t, 0f, 1f);

            var labelPos = new Vector2(row.X, row.Y + 1);
            var valueText = IsInt ? ((int)MathF.Round(value)).ToString() : value.ToString("0.00");
            var valuePos = new Vector2(track.X + track.Width + 4, row.Y + 1);

            sb.DrawString(context.Font, Label, labelPos, new Color(220, 220, 220, 200), 0f, Vector2.Zero, DebugTextScale, SpriteEffects.None, 0f);
            sb.DrawString(context.Font, valueText, valuePos, new Color(180, 180, 180, 200), 0f, Vector2.Zero, DebugTextScale, SpriteEffects.None, 0f);

            var trackRect = new Rectangle(track.X, row.Y + (row.Height - DebugSliderTrackHeight) / 2, track.Width, DebugSliderTrackHeight);
            sb.Draw(context.Pixel, trackRect, new Color(255, 255, 255, 60));

            var knobX = (int)(track.X + t * track.Width) - (DebugSliderKnobWidth / 2);
            var knobRect = new Rectangle(knobX, row.Y + (row.Height - DebugSliderKnobHeight) / 2, DebugSliderKnobWidth, DebugSliderKnobHeight);
            sb.Draw(context.Pixel, knobRect, new Color(255, 255, 255, 180));
        }

        public static Rectangle MakeTrackRect(Rectangle row, int labelWidth, int valueWidth)
        {
            var trackX = row.X + labelWidth;
            var trackWidth = Math.Max(1, row.Width - labelWidth - valueWidth);
            return new Rectangle(trackX, row.Y, trackWidth, row.Height);
        }
    }
}

