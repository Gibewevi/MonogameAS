using System;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace MonogameAS.Rendering;

/// <summary>
/// A small, point-sampled sky: cached dust, stepped sunlight and sparse moving stars.
/// All buffers are retained; only the tiny colour texture is refreshed, at 8 Hz.
/// </summary>
internal sealed class PixelSpaceBackdrop : IDisposable
{
    private const int PixelSize = 4;
    private const int NebulaSize = 128;
    private readonly Point _size;
    private readonly Texture2D _texture;
    private readonly Color[] _colors;
    private readonly float[] _dust;
    private readonly float[] _hue;
    private readonly Star[] _stars;
    private readonly bool _planetSky;
    private readonly float[] _nebula;
    private double _lastFrame = double.NegativeInfinity;
    private Color _lastSunlight;
    private double _time;
    private float _daylight;

    public PixelSpaceBackdrop(GraphicsDevice device, Point size, int seed, bool planetSky = false)
    {
        _size = size;
        _planetSky = planetSky;
        _nebula = planetSky ? Array.Empty<float>() : BuildNebula(seed);
        var width = Math.Max(1, (size.X + PixelSize - 1) / PixelSize);
        var height = Math.Max(1, (size.Y + PixelSize - 1) / PixelSize);
        _texture = new Texture2D(device, width, height);
        _colors = new Color[width * height];
        _dust = new float[_colors.Length];
        _hue = new float[_colors.Length];
        for (var y = 0; y < height; y++)
        for (var x = 0; x < width; x++)
        {
            var u = x / (float)width;
            var v = y / (float)height;
            var broad = Noise(u * 5f, v * 4f, seed);
            var detail = Noise(u * 15f, v * 12f, seed ^ 1729);
            var wisps = Noise(u * 32f, v * 26f, seed ^ 8191);
            _dust[y * width + x] = Math.Clamp((broad * .65f + detail * .25f + wisps * .1f - .3f) * 1.7f, 0f, 1f);
            _hue[y * width + x] = Noise(u * 4f + 8f, v * 3f, seed ^ 2833);
        }

        var rng = new Random(seed ^ 0x15376A);
        _stars = new Star[Math.Clamp(size.X * size.Y / 1700, 40, 200)];
        for (var i = 0; i < _stars.Length; i++)
        {
            var layer = rng.Next(3);
            var tint = rng.Next(4) switch
            {
                0 => new Color(154, 177, 201),
                1 => new Color(209, 170, 168),
                2 => new Color(160, 186, 177),
                _ => new Color(200, 198, 188)
            };
            _stars[i] = new Star(new Vector2(rng.Next(size.X), rng.Next(size.Y)),
                tint, (float)rng.NextDouble() * MathF.Tau, layer, i % 29 == 0);
        }
    }

    public void Update(double seconds, Color sunlight, Vector2 sunPosition, float daylight = 1f)
    {
        _time = seconds;
        _daylight = Math.Clamp(daylight, 0f, 1f);
        // A new stellar colour must be visible immediately, even at the same time/seed.
        if (sunlight == _lastSunlight && seconds >= _lastFrame && seconds - _lastFrame < .125) return;
        _lastFrame = seconds;
        _lastSunlight = sunlight;
        var sun = sunlight.ToVector3();
        if (_planetSky)
        {
            UpdatePlanetSky(sun, sunPosition);
            _texture.SetData(_colors);
            return;
        }
        UpdateSystemSky(sun, sunPosition);
        _texture.SetData(_colors);
    }

    private void UpdateSystemSky(Vector3 sun, Vector2 sunPosition)
    {
        var hue = Hue(sun);
        var warmth = Math.Clamp((sun.X - Math.Max(sun.Y * .75f, sun.Z)) * 3f, 0f, 1f);
        var shadowHue = hue + MathHelper.Lerp(.14f, -.30f, warmth);
        var middleHue = hue + MathHelper.Lerp(.07f, -.13f, warmth);
        var deep = Hsv(shadowHue, .62f, .045f);
        var ambient = Hsv(middleHue, .70f, .083f);
        var coolGas = Hsv(shadowHue, .64f, .17f);
        var litGas = Hsv(middleHue, .73f, .15f);
        // Two slowly drifting samples of a seamless, cached field. No per-frame noise
        // generation or particle storage: the fixed atlas is sampled and then quantised.
        var driftX = (float)(_time * .085 % NebulaSize);
        var driftY = (float)(_time * .027 % NebulaSize);
        var counterDrift = (float)(_time * .037 % NebulaSize);
        var breath = .94f + .06f * MathF.Sin((float)(_time % 10000) * .045f);
        var width = _texture.Width;
        var height = _texture.Height;
        for (var y = 0; y < height; y++)
        for (var x = 0; x < width; x++)
        {
            var i = y * width + x;
            var dx = (x * PixelSize - sunPosition.X) / Math.Max(1f, _size.X * .62f);
            var dy = (y * PixelSize - sunPosition.Y) / Math.Max(1f, _size.Y * .85f);
            var distance = dx * dx + dy * dy;
            var glow = MathF.Floor(Math.Max(0f, 1f - distance) * 8f) / 8f;
            var band = MathF.Floor((y / (float)height * .55f + glow * .45f) * 12f) / 12f;
            var rgb = Vector3.Lerp(deep, ambient, band);

            var a = SampleNebula(x * .76f + driftX, y * .92f + driftY);
            var b = SampleNebula(x * .94f - y * .17f - counterDrift + 43f,
                y * 1.06f + x * .12f + counterDrift * .4f + 67f);
            var density = Math.Clamp((a * .72f + b * .28f - .40f) * 2.8f, 0f, 1f);
            var mist = MathF.Floor(density * breath * 6f) / 6f;
            var wisps = MathF.Floor(Math.Max(0f, b - .50f) * 12f) / 6f;
            var gas = Vector3.Lerp(coolGas, litGas, MathF.Floor(_hue[i] * 4f) / 4f);
            // Leave quiet space around the sun and inner orbits; tint the outer wisps.
            var clearing = .42f + .58f * Math.Min(1f, distance * 2.4f);
            rgb += gas * mist * clearing;
            rgb += coolGas * wisps * .17f;
            rgb += sun * (glow * 8f + mist * clearing * 5f);
            rgb += HazeDust(_dust[i]);
            _colors[i] = new Color((int)rgb.X, (int)rgb.Y, (int)rgb.Z);
        }
    }

    private static Vector3 HazeDust(float density) => new Vector3(MathF.Floor(density * 4f) * .55f);

    private static float[] BuildNebula(int seed)
    {
        var field = new float[NebulaSize * NebulaSize];
        for (var y = 0; y < NebulaSize; y++)
        for (var x = 0; x < NebulaSize; x++)
        {
            var u = x / (float)NebulaSize;
            var v = y / (float)NebulaSize;
            field[y * NebulaSize + x] = TileNoise(u * 4, v * 4, 4, seed ^ 0x62A9) * .60f
                + TileNoise(u * 8, v * 8, 8, seed ^ 0x3AB1) * .27f
                + TileNoise(u * 16, v * 16, 16, seed ^ 0x51C3) * .13f;
        }
        return field;
    }

    private static float TileNoise(float x, float y, int period, int seed)
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

    private float SampleNebula(float x, float y)
    {
        var ix = (int)MathF.Floor(x);
        var iy = (int)MathF.Floor(y);
        var u = x - ix;
        var v = y - iy;
        const int mask = NebulaSize - 1;
        var x0 = ix & mask;
        var y0 = iy & mask;
        var x1 = (ix + 1) & mask;
        var y1 = (iy + 1) & mask;
        return MathHelper.Lerp(MathHelper.Lerp(_nebula[y0 * NebulaSize + x0], _nebula[y0 * NebulaSize + x1], u),
            MathHelper.Lerp(_nebula[y1 * NebulaSize + x0], _nebula[y1 * NebulaSize + x1], u), v);
    }

    private void UpdatePlanetSky(Vector3 sun, Vector2 sunPosition)
    {
        var hue = Hue(sun);
        var warmth = Math.Clamp((sun.X - Math.Max(sun.Y * .75f, sun.Z)) * 3f, 0f, 1f);
        // Analogous shadow hues: amber -> plum, green -> teal, blue -> indigo.
        // They follow the generated sun palette, including its deliberately fanciful colours.
        var zenithHue = hue + MathHelper.Lerp(.14f, -.30f, warmth);
        var duskHue = hue + MathHelper.Lerp(.07f, -.13f, warmth);
        var day = _daylight * _daylight * (3f - 2f * _daylight);
        var zenith = Hsv(zenithHue, .78f, MathHelper.Lerp(.038f, .115f, day));
        var dusk = Hsv(duskHue, .84f, MathHelper.Lerp(.065f, .26f, day));
        var horizon = Hsv(hue, .85f, MathHelper.Lerp(.09f, .53f, day));
        var haze = Hsv(zenithHue, .58f, 1f);
        var width = _texture.Width;
        var height = _texture.Height;
        for (var y = 0; y < height; y++)
        for (var x = 0; x < width; x++)
        {
            var i = y * width + x;
            var dust = _dust[i];
            // Broad horizontal colour bands, broken very slightly by cached pixel dust.
            var v = Math.Clamp((y + .5f) / height + (dust - .5f) * .025f, 0f, 1f);
            var band = MathF.Floor(v * 32f) / 32f;
            var upper = Math.Clamp(band / .72f, 0f, 1f);
            var lower = Math.Clamp((band - .55f) / .45f, 0f, 1f);
            var rgb = Vector3.Lerp(zenith, dusk, upper * upper);
            rgb = Vector3.Lerp(rgb, horizon, lower * lower);

            // The small sun lights a broad portion of the sky, not a nearby glowing disc.
            var dx = (x * PixelSize - sunPosition.X) / Math.Max(1f, _size.X * .64f);
            var dy = (y * PixelSize - sunPosition.Y) / Math.Max(1f, _size.Y * .78f);
            var glow = Math.Max(0f, 1f - dx * dx - dy * dy);
            glow = MathF.Floor(glow * 7f) / 7f;
            var lightPool = Math.Max(0f, 1f - dx * dx);
            lightPool = MathF.Floor(lightPool * 6f) / 6f;
            rgb += sun * glow * (2f + day * 7f);
            rgb += sun * lightPool * lower * lower * (3f + day * 12f);
            var dustStep = MathF.Floor(dust * 5f) / 5f;
            rgb += haze * dustStep * (.006f + day * .012f);
            _colors[i] = new Color((int)rgb.X, (int)rgb.Y, (int)rgb.Z);
        }
    }

    private static float Hue(Vector3 rgb)
    {
        var max = Math.Max(rgb.X, Math.Max(rgb.Y, rgb.Z));
        var min = Math.Min(rgb.X, Math.Min(rgb.Y, rgb.Z));
        var delta = max - min;
        if (delta < .0001f) return .12f;
        var hue = max == rgb.X ? (rgb.Y - rgb.Z) / delta
            : max == rgb.Y ? (rgb.Z - rgb.X) / delta + 2f : (rgb.X - rgb.Y) / delta + 4f;
        return (hue / 6f + 1f) % 1f;
    }

    // Values are in display-byte space so the stepped sky can be written directly.
    private static Vector3 Hsv(float hue, float saturation, float value)
    {
        hue = (hue % 1f + 1f) % 1f * 6f;
        var chroma = value * saturation;
        var x = chroma * (1f - Math.Abs(hue % 2f - 1f));
        var rgb = hue switch
        {
            < 1f => new Vector3(chroma, x, 0f),
            < 2f => new Vector3(x, chroma, 0f),
            < 3f => new Vector3(0f, chroma, x),
            < 4f => new Vector3(0f, x, chroma),
            < 5f => new Vector3(x, 0f, chroma),
            _ => new Vector3(chroma, 0f, x)
        };
        return (rgb + new Vector3(value - chroma)) * 255f;
    }

    public void Draw(SpriteBatch sb, Texture2D pixel)
    {
        sb.Draw(_texture, new Rectangle(0, 0, _size.X, _size.Y), Color.White);
        foreach (var star in _stars)
        {
            var speed = .12 + star.Layer * .17;
            var x = Wrap(star.Position.X - _time * speed, _size.X);
            var y = Wrap(star.Position.Y + _time * speed * .13, _size.Y);
            var twinkle = MathF.Floor((MathF.Sin((float)(_time % 10000) * .65f + star.Phase) * .5f + .5f) * 3f) / 3f;
            var brightness = (.24f + star.Layer * .14f + twinkle * .13f) * (1f - .12f * _daylight);
            // Blend into the coloured sky without painting dark squares around the stars.
            var color = star.Tint * brightness;
            sb.Draw(pixel, new Rectangle(x, y, 1, 1), color);
            if (star.Cross)
            {
                var arm = color * (.3f + twinkle * .15f);
                sb.Draw(pixel, new Rectangle(x - 2, y, 2, 1), arm);
                sb.Draw(pixel, new Rectangle(x + 1, y, 2, 1), arm);
                sb.Draw(pixel, new Rectangle(x, y - 2, 1, 2), arm);
                sb.Draw(pixel, new Rectangle(x, y + 1, 1, 2), arm);
            }
        }
    }

    public void Dispose() => _texture.Dispose();

    private static int Wrap(double value, int extent) => (int)((value % extent + extent) % extent);

    private static float Noise(float x, float y, int seed)
    {
        var ix = (int)MathF.Floor(x);
        var iy = (int)MathF.Floor(y);
        var u = x - ix;
        var v = y - iy;
        u *= u * (3f - 2f * u);
        v *= v * (3f - 2f * v);
        return MathHelper.Lerp(MathHelper.Lerp(Hash(ix, iy, seed), Hash(ix + 1, iy, seed), u),
            MathHelper.Lerp(Hash(ix, iy + 1, seed), Hash(ix + 1, iy + 1, seed), u), v);
    }

    private static float Hash(int x, int y, int seed)
    {
        unchecked
        {
            var n = (uint)(seed ^ x * 374761393 ^ y * 668265263);
            n = (n ^ (n >> 13)) * 1274126177u;
            return (n ^ (n >> 16)) / (float)uint.MaxValue;
        }
    }

    private readonly record struct Star(Vector2 Position, Color Tint, float Phase, int Layer, bool Cross);
}
