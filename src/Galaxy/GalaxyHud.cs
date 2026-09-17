using System;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace MonogameAS.Galaxy;

internal enum GalaxyHudAction
{
    None,
    ZoomOut,
    ZoomIn,
    Home,
    OpenSystem,
    FocusSelection
}

internal readonly record struct GalaxyHudState(
    Point Sector,
    int SystemsCount,
    int TilesCount,
    int Zoom,
    string? SelectedName = null,
    string? ClassDescription = null,
    Point? SelectedSector = null,
    bool CanOpen = false,
    GalaxyHudAction HoverAction = GalaxyHudAction.None,
    string? Hint = null);

/// <summary>Small, fixed-resolution navigation furniture; all drawing stays on the pixel grid.</summary>
internal sealed class GalaxyHud
{
    private static readonly Color Ink = new(16, 21, 39);
    private static readonly Color Panel = new(23, 29, 49);
    private static readonly Color Border = new(58, 67, 95);
    private static readonly Color White = new(226, 234, 245);
    private static readonly Color Muted = new(170, 183, 206);
    private static readonly Color Mint = new(153, 224, 206);
    private static readonly Color Lavender = new(185, 176, 230);
    private readonly RenderContext _context;
    private int _cachedSystems = -1;
    private int _cachedTiles = -1;
    private int _cachedZoom = -1;
    private Point _cachedSector = new(int.MinValue, int.MinValue);
    private Point _cachedSelectedSector = new(int.MinValue, int.MinValue);
    private string _countsText = string.Empty;
    private string _sectorText = string.Empty;
    private string _selectedSectorText = string.Empty;
    private string _zoomText = string.Empty;

    public GalaxyHud(RenderContext context) => _context = context;

    public Rectangle MapBounds => new(12, 60, 428, 244);
    public Rectangle CardBounds => new(452, 60, 176, 244);
    public Rectangle PreviewBounds => new(512, 96, 56, 56);
    private Rectangle ZoomOutBounds => new(442, 318, 28, 28);
    private Rectangle ZoomInBounds => new(514, 318, 28, 28);
    private Rectangle HomeBounds => new(550, 318, 78, 28);
    private Rectangle OpenBounds => new(464, 222, 152, 29);
    private Rectangle FocusBounds => new(464, 259, 152, 25);

    public bool IsPointerOverUi(Point point) => !MapBounds.Contains(point);

    public GalaxyHudAction HitTest(Point point)
    {
        if (ZoomOutBounds.Contains(point)) return GalaxyHudAction.ZoomOut;
        if (ZoomInBounds.Contains(point)) return GalaxyHudAction.ZoomIn;
        if (HomeBounds.Contains(point)) return GalaxyHudAction.Home;
        if (OpenBounds.Contains(point)) return GalaxyHudAction.OpenSystem;
        if (FocusBounds.Contains(point)) return GalaxyHudAction.FocusSelection;
        return GalaxyHudAction.None;
    }

    /// <remarks>The caller draws a selected star inside PreviewBounds after this method.</remarks>
    public void Draw(SpriteBatch batch, GalaxyHudState state)
    {
        UpdateLabels(state);
        DrawFrame(batch, MapBounds, Border * 0.70f);
        Text(batch, "Carte stellaire", new Vector2(410, 12), White, 0.63f);
        Text(batch, _countsText, new Vector2(412, 33), Muted, 0.50f, 216);

        DrawCard(batch, state);
        DrawFooter(batch, state);
    }

    private void UpdateLabels(GalaxyHudState state)
    {
        if (_cachedSystems != state.SystemsCount || _cachedTiles != state.TilesCount)
        {
            _cachedSystems = state.SystemsCount;
            _cachedTiles = state.TilesCount;
            _countsText = $"{state.SystemsCount} systèmes  /  {state.TilesCount} secteurs";
        }
        if (_cachedSector != state.Sector)
        {
            _cachedSector = state.Sector;
            _sectorText = $"{state.Sector.X} : {state.Sector.Y}";
        }
        if (_cachedZoom != state.Zoom)
        {
            _cachedZoom = state.Zoom;
            _zoomText = $"x{state.Zoom}";
        }
        var selectedSector = state.SelectedSector ?? state.Sector;
        if (state.CanOpen && _cachedSelectedSector != selectedSector)
        {
            _cachedSelectedSector = selectedSector;
            _selectedSectorText = $"Secteur {selectedSector.X} : {selectedSector.Y}";
        }
    }

    private void DrawCard(SpriteBatch batch, GalaxyHudState state)
    {
        PanelBox(batch, CardBounds, Panel, Border);
        CenterText(batch, state.CanOpen ? "SYSTÈME CHOISI" : "EXPLORATION", 69, 464, 152, Lavender, 0.50f);

        if (state.CanOpen)
        {
            // A restrained inset leaves room for the same animated sun used in the map.
            var preview = new Rectangle(500, 90, 80, 70);
            PanelBox(batch, preview, Ink, new Color(45, 52, 77));
            PixelStar(batch, new Point(489, 112), new Color(105, 129, 159));
            PixelStar(batch, new Point(594, 142), new Color(132, 122, 160));
            CenterText(batch, state.SelectedName ?? "Système inconnu", 170, 464, 152, White, 0.61f);
            CenterText(batch, state.ClassDescription ?? "Étoile lointaine", 190, 464, 152, Muted, 0.52f);
            CenterText(batch, _selectedSectorText, 205, 464, 152, Muted, 0.50f);
            DrawButton(batch, OpenBounds, "Voir le système", GalaxyHudAction.OpenSystem, state, true, true);
            DrawButton(batch, FocusBounds, "Centrer sur l'étoile", GalaxyHudAction.FocusSelection, state, true, false);
        }
        else
        {
            DrawConstellation(batch);
            CenterText(batch, "Un petit univers", 168, 464, 152, White, 0.56f);
            CenterText(batch, "à découvrir", 188, 464, 152, White, 0.56f);
            CenterText(batch, "Choisissez une étoile", 224, 464, 152, Muted, 0.50f);
            CenterText(batch, "pour visiter son système.", 241, 464, 152, Muted, 0.50f);
            CenterText(batch, "Cases + : explorer", 275, 464, 152, Lavender, 0.50f);
        }
    }

    private void DrawFooter(SpriteBatch batch, GalaxyHudState state)
    {
        PanelBox(batch, new Rectangle(12, 316, 416, 32), Ink, new Color(37, 46, 68));
        DrawCrosshair(batch, new Point(25, 331), Mint);
        Text(batch, _sectorText, new Vector2(38, 323), Mint, 0.52f, 82);
        // Permanent concise controls; situational hints may replace the second line.
        Text(batch, "Glisser : déplacer  /  Molette : zoom", new Vector2(132, 317), White, 0.50f, 288);
        Text(batch, state.Hint ?? "Flèches / ZQSD   |   Entrée : visiter", new Vector2(132, 332), Muted, 0.48f, 288);

        DrawButton(batch, ZoomOutBounds, "-", GalaxyHudAction.ZoomOut, state, state.Zoom > 1, false);
        DrawButton(batch, ZoomInBounds, "+", GalaxyHudAction.ZoomIn, state, state.Zoom < 4, false);
        CenterText(batch, _zoomText, 322, 473, 38, White, 0.57f);
        DrawButton(batch, HomeBounds, "Origine", GalaxyHudAction.Home, state, true, false);
    }

    private void DrawButton(SpriteBatch batch, Rectangle bounds, string label, GalaxyHudAction action,
        GalaxyHudState state, bool enabled, bool primary)
    {
        var hover = enabled && state.HoverAction == action;
        var fill = primary ? new Color(72, 122, 117) : new Color(33, 42, 63);
        var edge = primary ? new Color(135, 208, 187) : new Color(66, 81, 107);
        if (hover)
        {
            fill = Color.Lerp(fill, Mint, primary ? 0.24f : 0.16f);
            edge = Mint;
        }
        if (!enabled)
        {
            fill = new Color(21, 27, 43);
            edge = new Color(39, 47, 65);
        }
        PanelBox(batch, bounds, fill, edge);
        var scale = label.Length <= 1 ? 0.72f : label.Length > 15 ? 0.50f : 0.54f;
        var size = _context.Font.MeasureString(label) * scale;
        Text(batch, label, new Vector2(bounds.X + MathF.Floor((bounds.Width - size.X) * 0.5f),
            bounds.Y + MathF.Floor((bounds.Height - size.Y) * 0.5f) - 1), enabled ? White : new Color(79, 91, 114), scale);
    }

    private void DrawConstellation(SpriteBatch batch)
    {
        // Decorative miniature in the empty card, deliberately using hard square pixels.
        var a = new Point(502, 127);
        var b = new Point(534, 103);
        var c = new Point(575, 133);
        Line(batch, a, b, new Color(58, 75, 95));
        Line(batch, b, c, new Color(58, 75, 95));
        PixelStar(batch, a, Mint, 2);
        PixelStar(batch, b, new Color(251, 187, 154), 3);
        PixelStar(batch, c, Lavender, 2);
        batch.Draw(_context.Pixel, new Rectangle(489, 97, 2, 2), Muted * 0.65f);
        batch.Draw(_context.Pixel, new Rectangle(595, 109, 2, 2), Muted * 0.45f);
        batch.Draw(_context.Pixel, new Rectangle(554, 145, 2, 2), Muted * 0.55f);
    }

    private void CenterText(SpriteBatch batch, string text, int y, int x, int width, Color color, float scale)
    {
        // Names and coordinates can grow: fit the available card without crossing its frame.
        var measured = _context.Font.MeasureString(text);
        if (measured.X * scale > width) scale = width / measured.X;
        Text(batch, text, new Vector2(x + MathF.Floor((width - measured.X * scale) * 0.5f), y), color, scale);
    }

    private void Text(SpriteBatch batch, string text, Vector2 position, Color color, float scale, float maxWidth = float.MaxValue)
    {
        if (maxWidth < float.MaxValue)
        {
            var width = _context.Font.MeasureString(text).X;
            if (width * scale > maxWidth) scale = maxWidth / width;
        }
        position.X = MathF.Round(position.X);
        position.Y = MathF.Round(position.Y);
        batch.DrawString(_context.Font, text, position, color, 0f, Vector2.Zero, scale, SpriteEffects.None, 0f);
    }

    private void PanelBox(SpriteBatch batch, Rectangle rectangle, Color fill, Color border)
    {
        batch.Draw(_context.Pixel, new Rectangle(rectangle.X + 2, rectangle.Y, rectangle.Width - 4, rectangle.Height), fill);
        batch.Draw(_context.Pixel, new Rectangle(rectangle.X, rectangle.Y + 2, rectangle.Width, rectangle.Height - 4), fill);
        DrawFrame(batch, rectangle, border);
    }

    private void DrawFrame(SpriteBatch batch, Rectangle rectangle, Color color)
    {
        batch.Draw(_context.Pixel, new Rectangle(rectangle.X + 2, rectangle.Y, rectangle.Width - 4, 1), color);
        batch.Draw(_context.Pixel, new Rectangle(rectangle.X + 2, rectangle.Bottom - 1, rectangle.Width - 4, 1), color * 0.7f);
        batch.Draw(_context.Pixel, new Rectangle(rectangle.X, rectangle.Y + 2, 1, rectangle.Height - 4), color);
        batch.Draw(_context.Pixel, new Rectangle(rectangle.Right - 1, rectangle.Y + 2, 1, rectangle.Height - 4), color * 0.7f);
        batch.Draw(_context.Pixel, new Rectangle(rectangle.X + 1, rectangle.Y + 1, 1, 1), color);
        batch.Draw(_context.Pixel, new Rectangle(rectangle.Right - 2, rectangle.Y + 1, 1, 1), color);
        batch.Draw(_context.Pixel, new Rectangle(rectangle.X + 1, rectangle.Bottom - 2, 1, 1), color * 0.7f);
        batch.Draw(_context.Pixel, new Rectangle(rectangle.Right - 2, rectangle.Bottom - 2, 1, 1), color * 0.7f);
    }

    private void PixelStar(SpriteBatch batch, Point point, Color color, int unit = 1)
    {
        batch.Draw(_context.Pixel, new Rectangle(point.X - unit, point.Y - unit * 3, unit * 2, unit * 6), color);
        batch.Draw(_context.Pixel, new Rectangle(point.X - unit * 3, point.Y - unit, unit * 6, unit * 2), color);
        batch.Draw(_context.Pixel, new Rectangle(point.X - unit, point.Y - unit, unit * 2, unit * 2), White);
    }

    private void DrawCrosshair(SpriteBatch batch, Point point, Color color)
    {
        batch.Draw(_context.Pixel, new Rectangle(point.X - 1, point.Y - 5, 2, 10), color * 0.7f);
        batch.Draw(_context.Pixel, new Rectangle(point.X - 5, point.Y - 1, 10, 2), color * 0.7f);
        batch.Draw(_context.Pixel, new Rectangle(point.X - 2, point.Y - 2, 4, 4), Ink);
    }

    private void Line(SpriteBatch batch, Point from, Point to, Color color)
    {
        var steps = Math.Max(Math.Abs(to.X - from.X), Math.Abs(to.Y - from.Y));
        for (var step = 0; step <= steps; step += 3)
        {
            var x = from.X + (to.X - from.X) * step / steps;
            var y = from.Y + (to.Y - from.Y) * step / steps;
            batch.Draw(_context.Pixel, new Rectangle(x, y, 1, 1), color);
        }
    }
}
