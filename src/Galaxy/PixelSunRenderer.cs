using System;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using MonogameAS.State;

namespace MonogameAS.Galaxy;

/// <summary>
/// Seven-tone flowing plasma on a crisp circular grid. Normals and buffers are
/// retained, texture uploads run at 10 Hz, and at most seven prominences are drawn.
/// </summary>
internal sealed class PixelSunRenderer : IDisposable
{
    private readonly Texture2D _surface;
    private readonly Texture2D _corona;
    private readonly SolarPlasmaModel _plasma;
    private readonly Vector3[] _normals;
    private readonly Color[] _frame;
    private readonly Prominence[] _prominences;
    private readonly int _tiles;
    private readonly int _cellSize;
    private readonly int _diameter;
    private double _seconds;
    private long _frameTick = long.MinValue;

    public Color LightColor => _plasma.LightColor;

    public PixelSunRenderer(GraphicsDevice device, SunKey key, int diameter, int cellSize)
    {
        _cellSize = Math.Clamp(cellSize, 1, 16);
        _tiles = Math.Clamp(diameter / _cellSize, 4, 128);
        _diameter = _tiles * _cellSize;
        _plasma = new SolarPlasmaModel(key.Seed, key.Celsus > 0 ? key.Celsus : key.ClassId);
        _normals = new Vector3[_tiles * _tiles];
        _frame = new Color[_normals.Length];
        for (var y = 0; y < _tiles; y++)
        for (var x = 0; x < _tiles; x++)
        {
            var nx = (x + 0.5f) * 2f / _tiles - 1f;
            var ny = (y + 0.5f) * 2f / _tiles - 1f;
            var square = nx * nx + ny * ny;
            if (square <= 1f)
                _normals[y * _tiles + x] = new Vector3(nx, -ny, MathF.Sqrt(1f - square));
        }

        var rng = new Pcg32(key.Seed ^ 0x0179ac53);
        _prominences = new Prominence[Math.Clamp(_diameter / 17, 3, 7)];
        var startAngle = rng.NextFloatRange(0f, MathF.Tau);
        for (var i = 0; i < _prominences.Length; i++)
            _prominences[i] = new Prominence(startAngle + MathF.Tau * i / _prominences.Length + rng.NextFloatRange(-0.13f, 0.13f),
                rng.NextFloatRange(8f, 13f), rng.NextFloat(), rng.NextFloatRange(0.26f, 0.46f),
                rng.NextFloatRange(2.4f, 4.1f) * _cellSize, rng.NextFloatRange(-0.12f, 0.12f));

        // Two narrow, stepped contours follow the exact silhouette. No blur,
        // radial gradient texture, checkerboard noise or full-screen glow pass.
        const int padding = 2;
        var coronaSize = _tiles + padding * 2;
        var coronaPixels = new Color[coronaSize * coronaSize];
        for (var y = 0; y < coronaSize; y++)
        for (var x = 0; x < coronaSize; x++)
        {
            var sx = x - padding;
            var sy = y - padding;
            if (IsSurfaceCell(sx, sy)) continue;
            var nearest = 3;
            for (var oy = -2; oy <= 2; oy++)
            for (var ox = -2; ox <= 2; ox++)
                if (IsSurfaceCell(sx + ox, sy + oy))
                    nearest = Math.Min(nearest, Math.Abs(ox) + Math.Abs(oy));
            if (nearest == 1)
                coronaPixels[y * coronaSize + x] = _plasma.FlareColor * 0.24f;
            else if (nearest == 2)
                coronaPixels[y * coronaSize + x] = _plasma.RimColor * 0.055f;
        }
        _corona = new Texture2D(device, coronaSize, coronaSize);
        _corona.SetData(coronaPixels);
        _surface = new Texture2D(device, _tiles, _tiles);
        Update(0);
    }

    /// <param name="seconds">Absolute animation time, in seconds.</param>
    public void Update(double seconds)
    {
        if (!double.IsFinite(seconds)) return;
        _seconds = Math.Clamp(seconds, 0d, 1e12d);
        var tick = (long)(_seconds * 10d);
        if (tick == _frameTick) return;
        _frameTick = tick;
        var plasmaFrame = _plasma.At(tick * 0.1d);
        for (var i = 0; i < _normals.Length; i++)
        {
            if (_normals[i] == Vector3.Zero) continue;
            _frame[i] = _plasma.Sample(_normals[i], plasmaFrame);
        }
        _surface.SetData(_frame);
    }

    public void Draw(SpriteBatch sb, Texture2D pixel, Vector2 center, float scale = 1f)
    {
        if (!float.IsFinite(scale) || scale <= 0) return;
        var cell = _cellSize * scale;
        var coronaWidth = Math.Max(1, (int)MathF.Round(_corona.Width * cell));
        var pulse = 0.94f + 0.06f * MathF.Sin((float)(_seconds * 0.29d % Math.Tau));
        sb.Draw(_corona, Centered(center, coronaWidth), Color.White * pulse);
        DrawProminences(sb, pixel, center, scale);
        sb.Draw(_surface, Centered(center, Math.Max(1, (int)MathF.Round(_diameter * scale))), Color.White);
    }

    private void DrawProminences(SpriteBatch sb, Texture2D pixel, Vector2 center, float scale)
    {
        var cell = Math.Max(1, (int)MathF.Round(_cellSize * scale));
        var gridOrigin = center - new Vector2(_diameter * scale * 0.5f);
        var radius = _diameter * 0.5f - _cellSize * 0.7f;
        foreach (var prominence in _prominences)
        {
            var life = (float)((_seconds / prominence.Duration + prominence.Phase) % 1d);
            if (life > 0.8f) continue;
            var envelope = MathF.Sin(life / 0.8f * MathF.PI);
            var opacity = MathF.Round(envelope * 5f) / 5f;
            var height = prominence.Height * envelope;
            var tilt = prominence.Curl * envelope;
            var previous = new Point(int.MinValue, int.MinValue);

            // A small arch is anchored at two points of the surface grid; its
            // apex rises, curls slightly and returns while one ember drifts away.
            const int segments = 18;
            for (var i = 0; i <= segments; i++)
            {
                var u = i / (float)segments;
                var angle = prominence.Angle + (u - 0.5f) * prominence.Span + tilt * MathF.Sin(u * MathF.PI);
                var distance = radius + MathF.Sin(u * MathF.PI) * height;
                var position = center + new Vector2(MathF.Cos(angle), MathF.Sin(angle)) * distance * scale;
                var point = Snap(position, gridOrigin, cell);
                if (point == previous) continue;
                previous = point;
                var color = u > 0.35f && u < 0.65f ? _plasma.FlareColor : _plasma.RimColor;
                sb.Draw(pixel, new Rectangle(point.X, point.Y, cell, cell), color * (opacity * 0.72f));
            }

            if (life > 0.3f)
            {
                var flight = (life - 0.3f) / 0.5f;
                var angle = prominence.Angle + tilt + prominence.Curl * flight;
                var distance = radius + prominence.Height * (0.8f + flight * 0.95f);
                var position = center + new Vector2(MathF.Cos(angle), MathF.Sin(angle)) * distance * scale;
                var point = Snap(position, gridOrigin, cell);
                var emberAlpha = MathF.Round((1f - flight) * 4f) / 4f;
                sb.Draw(pixel, new Rectangle(point.X, point.Y, cell, cell), _plasma.FlareColor * (emberAlpha * 0.46f));
            }
        }
    }

    /// <summary>A distant, five-pixel sun drawn on a tiny rectangular grid.</summary>
    public void DrawDistant(SpriteBatch sb, Texture2D pixel, Vector2 center)
    {
        var x = (int)MathF.Round(center.X);
        var y = (int)MathF.Round(center.Y);
        var wave = MathF.Sin((float)(_seconds % 10000) * 0.52f) * 0.5f + 0.5f;
        var intensity = 0.92f + MathF.Floor(wave * 3f) * 0.027f;
        var halo = LightColor * (0.075f * intensity);
        sb.Draw(pixel, new Rectangle(x - 4, y - 1, 9, 3), halo);
        sb.Draw(pixel, new Rectangle(x - 3, y - 2, 7, 1), halo);
        sb.Draw(pixel, new Rectangle(x - 3, y + 2, 7, 1), halo);
        sb.Draw(pixel, new Rectangle(x - 1, y - 3, 3, 1), halo);
        sb.Draw(pixel, new Rectangle(x - 1, y + 3, 3, 1), halo);
        sb.Draw(pixel, new Rectangle(x - 2, y - 1, 5, 3), LightColor * intensity);
        sb.Draw(pixel, new Rectangle(x - 1, y - 1, 3, 2), _plasma.FlareColor * intensity);
        sb.Draw(pixel, new Rectangle(x - 1, y, 2, 1), _plasma.CoreColor * intensity);
    }

    public void Dispose()
    {
        _surface.Dispose();
        _corona.Dispose();
    }

    private bool IsSurfaceCell(int x, int y) =>
        x >= 0 && y >= 0 && x < _tiles && y < _tiles && _normals[y * _tiles + x] != Vector3.Zero;

    private static Point Snap(Vector2 position, Vector2 origin, int cell) =>
        new((int)MathF.Round(origin.X) + (int)MathF.Floor((position.X - origin.X) / cell) * cell,
            (int)MathF.Round(origin.Y) + (int)MathF.Floor((position.Y - origin.Y) / cell) * cell);

    private static Rectangle Centered(Vector2 center, int size) =>
        new((int)MathF.Round(center.X - size * 0.5f), (int)MathF.Round(center.Y - size * 0.5f), size, size);

    private readonly record struct Prominence(float Angle, float Duration, float Phase, float Span, float Height, float Curl);
}
