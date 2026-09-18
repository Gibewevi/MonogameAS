using System;
using System.Collections.Generic;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;
using MonogameAS.Galaxy;
using MonogameAS.Planet;
using MonogameAS.Rendering;
using MonogameAS.State;

namespace MonogameAS.Views;

/// <summary>A living pixel-art world with a permanent rotating spherical atlas.</summary>
public class PlanetView : IView, IDisposable
{
    private readonly RenderContext _context;
    private readonly GameState _state;
    private readonly PixelPlanetRenderer _planet;
    private PixelSpaceBackdrop? _backdrop;
    private PixelSunRenderer? _sun;
    private SunKey _sunKey;
    private int _backdropSeed;
    private Vector2 _sunPosition;
    private readonly List<DebugSlider> _planetSliders = new();
    private readonly List<DebugSlider> _cloudSliders = new();
    private readonly List<DebugSlider> _environmentSliders = new();
    private PlanetEnvironment _debugEnvironment;
    private bool _cloudActive = true;
    private bool _cloudUsePerlin = true;
    private bool _clipToCircle = true;
    private bool _clipDirty;
    private bool _showDebug;
    private bool _f3WasDown;
    private bool _ready;
    private double _seconds;
    private float _daylight;
    private int _ringOverride = -1;
    private int _moonOverride = -1;
    private int _decorationSeed;
    private DebugTab _activeTab = DebugTab.Planet;

    private const float DebugTextScale = 0.7f;
    private const int DebugPanelPadding = 6;
    private const int DebugPanelGap = 8;
    private const int DebugPanelTitleHeight = 14;
    private const int DebugSliderRowHeight = 20;
    private const int DebugSliderLabelWidth = 60;
    private const int DebugSliderValueWidth = 32;
    private const int DebugSliderTrackHeight = 6;
    private const int DebugSliderKnobWidth = 8;
    private const int DebugSliderKnobHeight = 12;
    private const int DebugTabHeight = 18;

    public PlanetView(RenderContext context, GameState state, PlanetProvider provider)
    {
        _context = context;
        _state = state;
        _planet = new PixelPlanetRenderer(context.GraphicsDevice);
        BuildDebugSliders();
    }

    public ViewMode Mode => ViewMode.Planet;

    public void Update(GameTime gameTime, MouseState mouse, MouseState previousMouse)
    {
        var f3Down = Keyboard.GetState().IsKeyDown(Keys.F3);
        if (f3Down && !_f3WasDown) _showDebug = !_showDebug;
        _f3WasDown = f3Down;
        var key = _state.PlanetKey;
        if (_decorationSeed != key.Seed)
        {
            _ringOverride = -1;
            _moonOverride = -1;
            _decorationSeed = key.Seed;
        }
        var parameters = key.Params;
        var initialEnvironment = key.ResolveEnvironment();
        _debugEnvironment = initialEnvironment;
        if (_showDebug && UpdateDebugUi(_context.ScreenToLogical(mouse.Position), mouse.LeftButton == ButtonState.Pressed,
            previousMouse.LeftButton == ButtonState.Pressed, ref parameters))
        {
            key = key with { Params = parameters };
            if (_debugEnvironment != initialEnvironment)
                key = key with { Environment = _debugEnvironment.Normalized() };
            _debugEnvironment = key.ResolveEnvironment();
            _state.SetPlanetKey(key);
        }
        _seconds = gameTime.TotalGameTime.TotalSeconds;
        UpdateScene(key);
    }

    private void UpdateScene(PlanetKey key)
    {
        if (_sun == null || _sunKey != _state.SunKey)
        {
            _sun?.Dispose();
            _sunKey = _state.SunKey;
            _sun = new PixelSunRenderer(_context.GraphicsDevice, _sunKey, 32, 2);
        }
        if (_backdrop == null || _backdropSeed != _state.SunKey.Seed)
        {
            _backdrop?.Dispose();
            _backdropSeed = _state.SunKey.Seed;
            _backdrop = new PixelSpaceBackdrop(_context.GraphicsDevice, _context.ViewSize, _backdropSeed, planetSky: true);
        }

        var viewport = GetPlanetViewport();
        // One continuous solar orbit drives the sun, the terminator and the sky.
        // Screen Y and the lighting vector use the same downward-positive convention.
        var phase = (float)((_seconds / 224.0 % 1.0) * MathHelper.TwoPi + 0.55);
        var light = Vector3.Normalize(new Vector3(MathF.Cos(phase), -0.30f, MathF.Sin(phase)));
        _daylight = 0.5f + light.Z * 0.5f;
        var center = new Vector2(viewport.X / 2f, viewport.Y / 2f + 12);
        _sunPosition = new Vector2(center.X + light.X * viewport.X * 0.31f,
            Math.Max(66, center.Y - viewport.Y * 0.27f - MathF.Sin(phase) * 12));
        _sun.Update(_seconds);
        _backdrop.Update(_seconds, _sun.LightColor, _sunPosition, _daylight);
        _planet.Update(key, viewport, _seconds, light, _sun.LightColor, _clipToCircle,
            _cloudActive, _cloudUsePerlin, _ringOverride, _moonOverride);
        _ready = true;
    }

    public void Draw(GameTime gameTime, RenderContext context)
    {
        if (!_ready)
        {
            _debugEnvironment = _state.PlanetKey.ResolveEnvironment();
            _seconds = gameTime.TotalGameTime.TotalSeconds;
            UpdateScene(_state.PlanetKey);
        }
        var sb = context.SpriteBatch;
        sb.Begin(samplerState: SamplerState.PointClamp, blendState: BlendState.AlphaBlend);
        _backdrop!.Draw(sb, context.Pixel);
        _sun!.DrawDistant(sb, context.Pixel, _sunPosition);
        _planet.Draw(sb, context.Pixel);

        const string label = "Vue planète";
        var size = context.Font.MeasureString(label);
        sb.DrawString(context.Font, label, new Vector2(context.ViewSize.X - size.X - 12, 14), new Color(218, 226, 237));
        DrawCycleIndicator(sb);
        if (_showDebug) DrawDebugPanels(sb, context.ViewSize, _state.PlanetKey.Params);
        else
        {
            sb.DrawString(context.Font, "F3  réglages", new Vector2(14, context.ViewSize.Y - 23),
                new Color(131, 145, 164), 0f, Vector2.Zero, 0.65f, SpriteEffects.None, 0f);
        }
        sb.End();
    }

    private void DrawCycleIndicator(SpriteBatch sb)
    {
        if (_showDebug) return;
        var x = _context.ViewSize.X - 92;
        var y = _context.ViewSize.Y - 19;
        for (var i = 0; i < 7; i++)
        {
            var filled = i / 6f <= _daylight;
            sb.Draw(_context.Pixel, new Rectangle(x + i * 8, y, 5, 3), filled ? new Color(206, 172, 140) : new Color(45, 52, 70));
        }
        sb.DrawString(_context.Font, "jour / nuit", new Vector2(x - 5, y - 13), new Color(137, 148, 165),
            0f, Vector2.Zero, 0.55f, SpriteEffects.None, 0f);
    }

    private Point GetPlanetViewport() => new(_context.ViewSize.X,
        Math.Max(1, _context.ViewSize.Y - (_showDebug ? GetDebugPanelHeight() : 20)));

    public void Dispose()
    {
        _planet.Dispose();
        _sun?.Dispose();
        _backdrop?.Dispose();
    }
    private void BuildDebugSliders()
    {
        _planetSliders.Clear();
        _cloudSliders.Clear();
        _environmentSliders.Clear();

        _planetSliders.Add(DebugSlider.Float("Radius", 12f, 240f, p => p.PlanetRadiusPx, (p, v) => p with { PlanetRadiusPx = (int)MathF.Round(v) }, isInt: true));
        _planetSliders.Add(DebugSlider.Float("Cell", 1f, 8f, p => p.CellSize, (p, v) => p with { CellSize = Math.Max(1, (int)MathF.Round(v)) }, isInt: true));
        _planetSliders.Add(DebugSlider.Float("ElevSc", 0.005f, 0.12f, p => p.ElevScale, (p, v) => p with { ElevScale = v }));
        _planetSliders.Add(DebugSlider.Float("Oct", 1f, 6f, p => p.ElevOctaves, (p, v) => p with { ElevOctaves = Math.Max(1, (int)MathF.Round(v)) }, isInt: true));
        _planetSliders.Add(DebugSlider.Float("Lac", 1.0f, 3.0f, p => p.ElevLacunarity, (p, v) => p with { ElevLacunarity = v }));
        _planetSliders.Add(DebugSlider.Float("Pers", 0.2f, 0.8f, p => p.ElevPersistence, (p, v) => p with { ElevPersistence = v }));
        _planetSliders.Add(DebugSlider.Float("Sea", 0.30f, 0.80f, p => p.ElevSeaLevel, (p, v) => p with { ElevSeaLevel = v }));
        _planetSliders.Add(DebugSlider.Float("Beach", 0.00f, 0.08f, p => p.ElevBeachBand, (p, v) => p with { ElevBeachBand = v }));
        _planetSliders.Add(DebugSlider.Float("Shelf", 0.00f, 0.20f, p => p.ElevShelfBand, (p, v) => p with { ElevShelfBand = v }));
        _planetSliders.Add(DebugSlider.Float("Hill", 0.50f, 0.90f, p => p.ElevHillLevel, (p, v) => p with { ElevHillLevel = v }));
        _planetSliders.Add(DebugSlider.Float("Mtn", 0.60f, 0.98f, p => p.ElevMtnLevel, (p, v) => p with { ElevMtnLevel = v }));
        _planetSliders.Add(DebugSlider.Float("Clip", 0f, 1f, _ => _clipToCircle ? 1f : 0f, (p, v) =>
        {
            _clipToCircle = v >= 0.5f;
            _clipDirty = true;
            return p;
        }, isInt: true));

        _planetSliders.Add(DebugSlider.Float("Rings", 0f, 3f, _ => _planet.RingCount,
            (p, v) => { _ringOverride = (int)MathF.Round(v); return p; }, isInt: true));
        _planetSliders.Add(DebugSlider.Float("Moons", 0f, 3f, _ => _planet.MoonCount,
            (p, v) => { _moonOverride = (int)MathF.Round(v); return p; }, isInt: true));

        _cloudSliders.Add(DebugSlider.Float("CScale", 0.01f, 0.05f, p => p.CloudScale, (p, v) => p with { CloudScale = v }));
        _cloudSliders.Add(DebugSlider.Float("CThresh", 0.20f, 0.80f, p => p.CloudThreshold, (p, v) => p with { CloudThreshold = v }));
        _cloudSliders.Add(DebugSlider.Float("COct", 1f, 4f, p => p.CloudOctaves, (p, v) => p with { CloudOctaves = Math.Max(1, (int)MathF.Round(v)) }, isInt: true));
        _cloudSliders.Add(DebugSlider.Float("CLac", 1.0f, 3.0f, p => p.CloudLacunarity, (p, v) => p with { CloudLacunarity = v }));
        _cloudSliders.Add(DebugSlider.Float("CPers", 0.3f, 0.8f, p => p.CloudPersistence, (p, v) => p with { CloudPersistence = v }));
        _cloudSliders.Add(DebugSlider.Float("CMargin", 0f, 12f, p => p.CloudMargin, (p, v) => p with { CloudMargin = v }));
        _cloudSliders.Add(DebugSlider.Float("CCell", 1f, 8f, p => p.CloudCellSize, (p, v) => p with { CloudCellSize = Math.Max(1, (int)MathF.Round(v)) }, isInt: true));
        _cloudSliders.Add(DebugSlider.Float("CGrid", 32f, 200f, p => p.CloudGridMarginPx, (p, v) => p with { CloudGridMarginPx = v }));
        _cloudSliders.Add(DebugSlider.Float("SpdX", -0.2f, 0.2f, p => p.CloudSpeed.X, (p, v) => p with { CloudSpeed = new Vector2(v, p.CloudSpeed.Y) }));
        _cloudSliders.Add(DebugSlider.Float("SpdY", -0.2f, 0.2f, p => p.CloudSpeed.Y, (p, v) => p with { CloudSpeed = new Vector2(p.CloudSpeed.X, v) }));
        _cloudSliders.Add(DebugSlider.Float("Active", 0f, 1f, _ => _cloudActive ? 1f : 0f, (p, v) => { _cloudActive = v >= 0.5f; return p; }, isInt: true));
        _cloudSliders.Add(DebugSlider.Float("Perlin", 0f, 1f, _ => _cloudUsePerlin ? 1f : 0f, (p, v) => { _cloudUsePerlin = v >= 0.5f; return p; }, isInt: true));
        _cloudSliders.Add(DebugSlider.Float("A1", 0f, 1f, _ => CloudRenderSettings.LightAlpha, (p, v) =>
        {
            CloudRenderSettings.LightAlpha = v;
            return p;
        }));
        _cloudSliders.Add(DebugSlider.Float("A2", 0f, 1f, _ => CloudRenderSettings.DarkAlpha, (p, v) =>
        {
            CloudRenderSettings.DarkAlpha = v;
            return p;
        }));

        AddEnvironmentSlider("Orb AU", 0.12f, 20f, e => e.OrbitalDistanceAu, (e, v) => e with { OrbitalDistanceAu = v });
        AddEnvironmentSlider("Etoile", 0.02f, 20f, e => e.StellarLuminosity, (e, v) => e with { StellarLuminosity = v });
        AddEnvironmentSlider("Atmo", 0f, 1f, e => e.Atmosphere, (e, v) => e with { Atmosphere = v });
        AddEnvironmentSlider("Serre", 0f, 1f, e => e.Greenhouse, (e, v) => e with { Greenhouse = v });
        AddEnvironmentSlider("Eau", 0f, 1f, e => e.Water, (e, v) => e with { Water = v });
        AddEnvironmentSlider("Sel", 0f, 1f, e => e.Salinity, (e, v) => e with { Salinity = v });
        AddEnvironmentSlider("Volcan", 0f, 1f, e => e.Volcanism, (e, v) => e with { Volcanism = v });
        AddEnvironmentSlider("Plaques", 0f, 1f, e => e.Tectonics, (e, v) => e with { Tectonics = v });
        AddEnvironmentSlider("Age Gyr", 0.02f, 12f, e => e.AgeGyr, (e, v) => e with { AgeGyr = v });
        AddEnvironmentSlider("Impacts", 0f, 1f, e => e.Impacts, (e, v) => e with { Impacts = v });
        AddEnvironmentSlider("Erosion", 0f, 1f, e => e.Erosion, (e, v) => e with { Erosion = v });
        AddEnvironmentSlider("Axe", 0f, 90f, e => e.AxialTilt, (e, v) => e with { AxialTilt = v });
        AddEnvironmentSlider("Fer", 0f, 1f, e => e.Iron, (e, v) => AdjustComposition(e, 0, v));
        AddEnvironmentSlider("Silicate", 0f, 1f, e => e.Silicates, (e, v) => AdjustComposition(e, 1, v));
        AddEnvironmentSlider("Carbone", 0f, 1f, e => e.Carbon, (e, v) => AdjustComposition(e, 2, v));
        AddEnvironmentSlider("Vie", 0f, 1f, e => e.LifePotential, (e, v) => e with { LifePotential = v });
        AddEnvironmentSlider("Cont", 0.7f, 5f, e => e.ContinentalScale, (e, v) => e with { ContinentalScale = v });
        AddEnvironmentSlider("Relief", 0f, 1f, e => e.Relief, (e, v) => e with { Relief = v });
    }

    private void AddEnvironmentSlider(string label, float min, float max,
        Func<PlanetEnvironment, float> getter, Func<PlanetEnvironment, float, PlanetEnvironment> setter)
    {
        _environmentSliders.Add(DebugSlider.Float(label, min, max, _ => getter(_debugEnvironment), (p, value) =>
        {
            _debugEnvironment = setter(_debugEnvironment, value);
            return p;
        }));
    }

    private static PlanetEnvironment AdjustComposition(PlanetEnvironment environment, int component, float value)
    {
        // Keep the selected mineral at the slider value, distributing the remaining
        // composition in the same ratio as before the edit.
        var iron = component == 0 ? 0 : environment.Iron;
        var silicates = component == 1 ? 0 : environment.Silicates;
        var carbon = component == 2 ? 0 : environment.Carbon;
        var total = iron + silicates + carbon;
        var remaining = 1f - value;
        var scale = total > 0 ? remaining / total : 0;
        return environment with
        {
            Iron = component == 0 ? value : total > 0 ? iron * scale : remaining * 0.5f,
            Silicates = component == 1 ? value : total > 0 ? silicates * scale : remaining * 0.5f,
            Carbon = component == 2 ? value : total > 0 ? carbon * scale : remaining * 0.5f
        };
    }

    private bool UpdateDebugUi(Point mouse, bool leftDown, bool leftPrev, ref PlanetParams p)
    {
        var view = _context.ViewSize;
        var panelHeight = GetDebugPanelHeight();
        var panelY = view.Y - panelHeight;
        if (mouse.Y < panelY)
            return false;

        var panelWidth = view.X - DebugPanelGap * 2;
        var panel = new Rectangle(DebugPanelGap, panelY, panelWidth, panelHeight);
        var changed = false;
        changed |= UpdateTabPanel(panel, mouse, leftDown, leftPrev);
        changed |= UpdateSliderPanel(ActiveSliders, panel, mouse, leftDown, leftPrev, ref p);
        if (_clipDirty)
        {
            _clipDirty = false;
            changed = true;
        }
        return changed;
    }

    private bool UpdateSliderPanel(List<DebugSlider> sliders, Rectangle panel, Point mouse, bool leftDown, bool leftPrev, ref PlanetParams p)
    {
        var columns = 2;
        var rows = (int)MathF.Ceiling(sliders.Count / (float)columns);
        var colWidth = (panel.Width - DebugPanelPadding * 2 - DebugPanelGap) / columns;
        var startY = panel.Y + DebugPanelTitleHeight + DebugPanelPadding + DebugTabHeight;
        var changed = false;

        for (var i = 0; i < sliders.Count; i++)
        {
            var col = i / rows;
            var row = i % rows;
            var x = panel.X + DebugPanelPadding + col * (colWidth + DebugPanelGap);
            var y = startY + row * DebugSliderRowHeight;
            var rowRect = new Rectangle(x, y, colWidth, DebugSliderRowHeight);
            var trackRect = DebugSlider.MakeTrackRect(rowRect, DebugSliderLabelWidth, DebugSliderValueWidth);
            if (sliders[i].Update(mouse, leftDown, leftPrev, trackRect, ref p))
                changed = true;
        }

        return changed;
    }

    private void DrawDebugPanels(SpriteBatch sb, Point view, PlanetParams p)
    {
        var panelHeight = GetDebugPanelHeight();
        var panelY = view.Y - panelHeight;
        var panelWidth = view.X - DebugPanelGap * 2;
        var panel = new Rectangle(DebugPanelGap, panelY, panelWidth, panelHeight);

        var bg = new Color(15, 21, 34) * 0.95f;
        var outline = new Color(106, 135, 158) * 0.45f;
        sb.Draw(_context.Pixel, panel, bg);
        DrawRectOutline(sb, _context.Pixel, panel, outline);

        DrawTabs(sb, panel);
        DrawSliderPanel(sb, ActiveSliders, panel, p);
    }

    private void DrawSliderPanel(SpriteBatch sb, List<DebugSlider> sliders, Rectangle panel, PlanetParams p)
    {
        var columns = 2;
        var rows = (int)MathF.Ceiling(sliders.Count / (float)columns);
        var colWidth = (panel.Width - DebugPanelPadding * 2 - DebugPanelGap) / columns;
        var startY = panel.Y + DebugPanelTitleHeight + DebugPanelPadding + DebugTabHeight;

        for (var i = 0; i < sliders.Count; i++)
        {
            var col = i / rows;
            var row = i % rows;
            var x = panel.X + DebugPanelPadding + col * (colWidth + DebugPanelGap);
            var y = startY + row * DebugSliderRowHeight;
            var rowRect = new Rectangle(x, y, colWidth, DebugSliderRowHeight);
            sliders[i].Draw(sb, _context, rowRect, p);
        }
    }

    private List<DebugSlider> ActiveSliders => _activeTab switch
    {
        DebugTab.Planet => _planetSliders,
        DebugTab.Clouds => _cloudSliders,
        _ => _environmentSliders
    };

    private int GetDebugPanelHeight()
    {
        var activeCount = ActiveSliders.Count;
        var rows = Math.Max(1, (int)MathF.Ceiling(activeCount / 2f));
        return DebugPanelTitleHeight + DebugPanelPadding * 2 + DebugTabHeight + rows * DebugSliderRowHeight;
    }

    private static void DrawRectOutline(SpriteBatch sb, Texture2D pixel, Rectangle rect, Color color)
    {
        sb.Draw(pixel, new Rectangle(rect.X, rect.Y, rect.Width, 1), color);
        sb.Draw(pixel, new Rectangle(rect.X, rect.Y + rect.Height - 1, rect.Width, 1), color);
        sb.Draw(pixel, new Rectangle(rect.X, rect.Y, 1, rect.Height), color);
        sb.Draw(pixel, new Rectangle(rect.X + rect.Width - 1, rect.Y, 1, rect.Height), color);
    }

    private bool UpdateTabPanel(Rectangle panel, Point mouse, bool leftDown, bool leftPrev)
    {
        var tabArea = new Rectangle(panel.X + DebugPanelPadding, panel.Y + DebugPanelTitleHeight + 2, panel.Width - DebugPanelPadding * 2, DebugTabHeight);
        if (!leftDown || leftPrev || !tabArea.Contains(mouse))
            return false;

        var tabWidth = Math.Max(1, tabArea.Width / 3);
        _activeTab = (DebugTab)Math.Clamp((mouse.X - tabArea.X) / tabWidth, 0, 2);

        return true;
    }

    private void DrawTabs(SpriteBatch sb, Rectangle panel)
    {
        var tabArea = new Rectangle(panel.X + DebugPanelPadding, panel.Y + DebugPanelTitleHeight + 2, panel.Width - DebugPanelPadding * 2, DebugTabHeight);
        var tabWidth = Math.Max(1, tabArea.Width / 3);
        var planetRect = new Rectangle(tabArea.X, tabArea.Y, tabWidth, tabArea.Height);
        var cloudRect = new Rectangle(tabArea.X + tabWidth, tabArea.Y, tabWidth, tabArea.Height);
        var environmentRect = new Rectangle(tabArea.X + tabWidth * 2, tabArea.Y, tabArea.Width - tabWidth * 2, tabArea.Height);

        var inactive = new Color(97, 120, 150) * 0.15f;
        var active = new Color(97, 145, 180) * 0.4f;
        sb.Draw(_context.Pixel, planetRect, _activeTab == DebugTab.Planet ? active : inactive);
        sb.Draw(_context.Pixel, cloudRect, _activeTab == DebugTab.Clouds ? active : inactive);
        sb.Draw(_context.Pixel, environmentRect, _activeTab == DebugTab.Environment ? active : inactive);

        sb.DrawString(_context.Font, "Planete", new Vector2(planetRect.X + 6, planetRect.Y + 2), new Color(220, 220, 220) * 0.8f, 0f, Vector2.Zero, DebugTextScale, SpriteEffects.None, 0f);
        sb.DrawString(_context.Font, "Nuages", new Vector2(cloudRect.X + 6, cloudRect.Y + 2), new Color(220, 220, 220) * 0.8f, 0f, Vector2.Zero, DebugTextScale, SpriteEffects.None, 0f);
        sb.DrawString(_context.Font, "Milieu", new Vector2(environmentRect.X + 6, environmentRect.Y + 2), new Color(220, 220, 220) * 0.8f, 0f, Vector2.Zero, DebugTextScale, SpriteEffects.None, 0f);
    }

    private enum DebugTab
    {
        Planet,
        Clouds,
        Environment
    }

    private sealed class DebugSlider
    {
        public string Label { get; }
        public float Min { get; }
        public float Max { get; }
        public bool IsInt { get; }
        public Func<PlanetParams, float> Getter { get; }
        public Func<PlanetParams, float, PlanetParams> Setter { get; }

        private bool _dragging;

        private DebugSlider(string label, float min, float max, Func<PlanetParams, float> getter, Func<PlanetParams, float, PlanetParams> setter, bool isInt)
        {
            Label = label;
            Min = min;
            Max = max;
            Getter = getter;
            Setter = setter;
            IsInt = isInt;
        }

        public static DebugSlider Float(string label, float min, float max, Func<PlanetParams, float> getter, Func<PlanetParams, float, PlanetParams> setter, bool isInt = false)
        {
            return new DebugSlider(label, min, max, getter, setter, isInt);
        }

        public bool Update(Point mouse, bool leftDown, bool leftPrev, Rectangle track, ref PlanetParams p)
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
                var previousValue = Getter(p);
                var updated = Setter(p, value);
                if (!updated.Equals(p) || Getter(updated) != previousValue)
                {
                    p = updated;
                    return true;
                }
            }

            return false;
        }

        public void Draw(SpriteBatch sb, RenderContext context, Rectangle row, PlanetParams p)
        {
            var track = MakeTrackRect(row, DebugSliderLabelWidth, DebugSliderValueWidth);
            var value = Getter(p);
            var t = Math.Abs(Max - Min) < 1e-6f ? 0f : (value - Min) / (Max - Min);
            t = Math.Clamp(t, 0f, 1f);

            var labelPos = new Vector2(row.X, row.Y + 1);
            var valueText = IsInt ? ((int)MathF.Round(value)).ToString() : value.ToString("0.00");
            var valuePos = new Vector2(track.X + track.Width + 4, row.Y + 1);

            sb.DrawString(context.Font, Label, labelPos, new Color(220, 220, 220) * 0.8f, 0f, Vector2.Zero, DebugTextScale, SpriteEffects.None, 0f);
            sb.DrawString(context.Font, valueText, valuePos, new Color(180, 180, 180) * 0.8f, 0f, Vector2.Zero, DebugTextScale, SpriteEffects.None, 0f);

            var trackRect = new Rectangle(track.X, row.Y + (row.Height - DebugSliderTrackHeight) / 2, track.Width, DebugSliderTrackHeight);
            sb.Draw(context.Pixel, trackRect, new Color(150, 171, 195) * 0.34f);

            var knobX = (int)(track.X + t * track.Width) - (DebugSliderKnobWidth / 2);
            var knobRect = new Rectangle(knobX, row.Y + (row.Height - DebugSliderKnobHeight) / 2, DebugSliderKnobWidth, DebugSliderKnobHeight);
            sb.Draw(context.Pixel, knobRect, new Color(187, 210, 228) * 0.86f);
        }

        public static Rectangle MakeTrackRect(Rectangle row, int labelWidth, int valueWidth)
        {
            var trackX = row.X + labelWidth;
            var trackWidth = Math.Max(1, row.Width - labelWidth - valueWidth);
            return new Rectangle(trackX, row.Y, trackWidth, row.Height);
        }
    }
}
