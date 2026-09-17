using System;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace MonogameAS.Rendering;

/// <summary>
/// Quiet, stepped nebulae beneath the navigable star map. The cached fields are
/// sampled at eight frames per second; the tiny distant stars stay one pixel wide.
/// </summary>
internal sealed class PixelGalaxyBackdrop : IDisposable
{
    private const int PixelSize = 4;
    private const int FieldSize = 128;
    private const double FrameInterval = 1d / 8d;
    private readonly Point _size;
    private readonly Texture2D _texture;
    private readonly Color[] _colors;
    private readonly float[] _cloudField;
    private readonly float[] _detailField;
    private readonly Star[] _stars;
    private readonly float _phase;
    private double _lastFrame = double.NegativeInfinity;
    private double _time;
    private Vector2 _camera;
    private float _zoom = 1f;
    private Color _lastAccent;

    public PixelGalaxyBackdrop(GraphicsDevice device, Point size, int seed)
    {
        _size = new Point(Math.Max(1, size.X), Math.Max(1, size.Y));
        _texture = new Texture2D(device, (_size.X + PixelSize - 1) / PixelSize,
            (_size.Y + PixelSize - 1) / PixelSize);
        _colors = new Color[_texture.Width * _texture.Height];
        _cloudField = BuildField(seed ^ 0x52D49);
        _detailField = BuildField(seed ^ 0x378BF);
        _phase = Hash(3, 11, seed) * MathF.Tau;

        var random = new Random(seed ^ 0x7159A);
        _stars = new Star[Math.Clamp(_size.X * _size.Y / 3000, 24, 120)];
        for (var i = 0; i < _stars.Length; i++)
        {
            var tint = random.Next(4) switch
            {
                0 => new Color(129, 156, 190),
                1 => new Color(179, 151, 181),
                2 => new Color(141, 178, 172),
                _ => new Color(185, 179, 168)
            };
            _stars[i] = new Star(new Vector2(random.Next(_size.X), random.Next(_size.Y)),
                tint, (float)random.NextDouble() * MathF.Tau, random.Next(3));
        }

        Update(0d, Vector2.Zero, 1f, new Color(158, 172, 218));
    }

    public void Update(double seconds, Vector2 cameraPosition, float zoom, Color accent)
    {
        _time = double.IsFinite(seconds) ? Math.Clamp(seconds, 0d, 1e12) : 0d;
        _camera = new Vector2(float.IsFinite(cameraPosition.X) ? cameraPosition.X : 0f,
            float.IsFinite(cameraPosition.Y) ? cameraPosition.Y : 0f);
        _zoom = float.IsFinite(zoom) ? Math.Clamp(zoom, .25f, 8f) : 1f;
        if (_lastAccent == accent && _time >= _lastFrame && _time - _lastFrame < FrameInterval)
            return;

        _lastFrame = _time;
        _lastAccent = accent;
        var driftX = (float)(_time * .031 % FieldSize);
        var driftY = (float)(_time * .012 % FieldSize);
        var panX = _camera.X * .012f;
        var panY = _camera.Y * .012f;
        var fieldScale = 1.02f - MathF.Min(_zoom, 4f) * .025f;
        var breath = .94f + .06f * MathF.Sin((float)(_time % 10000d) * .033f + _phase);
        var selectedHue = accent.ToVector3();
        var width = _texture.Width;
        var height = _texture.Height;

        for (var y = 0; y < height; y++)
        for (var x = 0; x < width; x++)
        {
            var u = x / (float)width;
            var v = y / (float)height;
            var px = x * fieldScale + panX + driftX;
            var py = y * fieldScale + panY - driftY;
            var cloud = Sample(_cloudField, px * .67f, py * .81f);
            var detail = Sample(_detailField, px * 1.12f + 37f, py * 1.06f + 59f);
            var curl = Sample(_detailField, px * .29f + 71f, py * .35f + 13f);

            // Broad diagonal cloud shelves, broken by dark channels. These are an
            // atmosphere behind a map, so their light remains well below the suns.
            var ribbonCenter = .68f - u * .35f + (curl - .5f) * .38f;
            var ribbon = Math.Clamp(1f - Math.Abs(v - ribbonCenter) * 2.1f, 0f, 1f);
            var density = Math.Clamp((cloud * .72f + detail * .28f - .37f) * 2.8f, 0f, 1f);
            var channel = Math.Clamp((detail - .36f) * 2.3f, .16f, 1f);
            var mist = Step(density * (.45f + ribbon * .55f) * breath, 7f);
            var thinCloud = Step(Math.Max(0f, detail - .52f) * 2.1f * ribbon, 5f);
            var warmSide = Step(Math.Clamp(curl * 1.4f - .18f, 0f, 1f), 4f);

            var baseShade = Step(Math.Clamp(v * .46f + ribbon * .23f, 0f, 1f), 12f);
            var rgb = Vector3.Lerp(new Vector3(7, 11, 24), new Vector3(15, 16, 32), baseShade);
            var gas = Vector3.Lerp(new Vector3(20, 27, 47), new Vector3(37, 22, 48), warmSide);
            rgb += gas * mist * channel * .74f;
            rgb += new Vector3(14, 27, 28) * thinCloud * .34f;

            // Only a hint of the selected star reaches this much wider view.
            rgb += selectedHue * (mist * 2.8f + thinCloud * 1.4f);
            var edgeX = (u - .5f) * 2f;
            var edgeY = (v - .5f) * 2f;
            var vignette = Step(Math.Clamp((edgeX * edgeX + edgeY * edgeY - .35f) * .48f, 0f, 1f), 6f);
            rgb *= 1f - vignette * .16f;
            _colors[y * width + x] = new Color((int)rgb.X, (int)rgb.Y, (int)rgb.Z);
        }

        _texture.SetData(_colors);
    }

    /// <summary>Draw in logical screen space inside an AlphaBlend / PointClamp batch.</summary>
    public void Draw(SpriteBatch batch, Texture2D pixel)
    {
        batch.Draw(_texture, new Rectangle(0, 0, _size.X, _size.Y), Color.White);
        var center = new Vector2(_size.X * .5f, _size.Y * .5f);
        foreach (var star in _stars)
        {
            var parallax = .034f + star.Layer * .019f;
            var zoomOffset = (star.Position - center) * ((_zoom - 1f) * .011f);
            var x = Wrap(star.Position.X + zoomOffset.X - _camera.X * parallax - _time * (.016 + star.Layer * .009), _size.X);
            var y = Wrap(star.Position.Y + zoomOffset.Y - _camera.Y * parallax + _time * .006, _size.Y);
            var twinkle = Step(MathF.Sin((float)(_time % 10000d) * .34f + star.Phase) * .5f + .5f, 3f);
            var brightness = .28f + star.Layer * .055f + twinkle * .105f;
            batch.Draw(pixel, new Rectangle(x, y, 1, 1), star.Tint * brightness);
        }
    }

    public void Dispose() => _texture.Dispose();

    private static float Step(float value, float steps) => MathF.Floor(value * steps) / steps;
    private static int Wrap(double value, int extent) => (int)((value % extent + extent) % extent);

    private static float[] BuildField(int seed)
    {
        var field = new float[FieldSize * FieldSize];
        for (var y = 0; y < FieldSize; y++)
        for (var x = 0; x < FieldSize; x++)
        {
            var u = x / (float)FieldSize;
            var v = y / (float)FieldSize;
            field[y * FieldSize + x] = Noise(u * 4f, v * 4f, 4, seed) * .58f
                + Noise(u * 8f, v * 8f, 8, seed ^ 0x3197) * .29f
                + Noise(u * 16f, v * 16f, 16, seed ^ 0x7149) * .13f;
        }
        return field;
    }

    private static float Sample(float[] field, float x, float y)
    {
        var ix = (int)MathF.Floor(x);
        var iy = (int)MathF.Floor(y);
        var u = x - ix;
        var v = y - iy;
        const int mask = FieldSize - 1;
        var x0 = ix & mask;
        var x1 = (ix + 1) & mask;
        var y0 = iy & mask;
        var y1 = (iy + 1) & mask;
        return MathHelper.Lerp(MathHelper.Lerp(field[y0 * FieldSize + x0], field[y0 * FieldSize + x1], u),
            MathHelper.Lerp(field[y1 * FieldSize + x0], field[y1 * FieldSize + x1], u), v);
    }

    private static float Noise(float x, float y, int period, int seed)
    {
        var ix = (int)MathF.Floor(x);
        var iy = (int)MathF.Floor(y);
        var u = x - ix;
        var v = y - iy;
        u *= u * (3f - 2f * u);
        v *= v * (3f - 2f * v);
        var x1 = (ix + 1) % period;
        var y1 = (iy + 1) % period;
        return MathHelper.Lerp(MathHelper.Lerp(Hash(ix, iy, seed), Hash(x1, iy, seed), u),
            MathHelper.Lerp(Hash(ix, y1, seed), Hash(x1, y1, seed), u), v);
    }

    private static float Hash(int x, int y, int seed)
    {
        unchecked
        {
            var value = (uint)(seed ^ x * 374761393 ^ y * 668265263);
            value = (value ^ (value >> 13)) * 1274126177u;
            return (value ^ (value >> 16)) / (float)uint.MaxValue;
        }
    }

    private readonly record struct Star(Vector2 Position, Color Tint, float Phase, int Layer);
}
