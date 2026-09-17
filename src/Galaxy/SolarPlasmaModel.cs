using System;
using Microsoft.Xna.Framework;

namespace MonogameAS.Galaxy;

/// <summary>
/// Resolution-independent, emissive plasma. Broad flowing fields produce connected
/// colour regions; there is no per-pixel randomness, terrain automaton or lighting map.
/// Both the galaxy baker and animated suns sample this same seven-colour model.
/// </summary>
internal sealed class SolarPlasmaModel
{
    private readonly int _seed;
    private readonly Vector3 _offset;
    private readonly float _phase;
    private readonly float _flowScale;
    private readonly Color[] _palette;

    public Color LightColor { get; }
    public Color RimColor => _palette[2];
    public Color FlareColor => _palette[4];
    public Color CoreColor => _palette[6];

    public SolarPlasmaModel(int seed, int temperatureOrClass)
    {
        _seed = seed;
        var rng = new Pcg32(seed ^ 0x0422da17);
        _phase = rng.NextFloatRange(0f, MathF.Tau);
        _offset = new Vector3(rng.NextFloatRange(10f, 40f), rng.NextFloatRange(10f, 40f), rng.NextFloatRange(10f, 40f));
        _flowScale = rng.NextFloatRange(2.1f, 2.65f);
        _palette = MakePalette(ResolveTemperature(temperatureOrClass), rng.NextFloat());
        // A palette colour, never a mean over a particular raster or animation frame.
        LightColor = Color.Lerp(_palette[3], _palette[4], 0.28f);
    }

    public Frame At(double seconds)
    {
        // Reduce angles in double precision so long-running sessions stay stable.
        var rotation = (float)((seconds * 0.067 + _phase) % Math.Tau);
        var flow = (float)((seconds * 0.041 + _phase) % Math.Tau);
        var breath = (float)((seconds * 0.29 + _phase) % Math.Tau);
        return new Frame(MathF.Cos(rotation), MathF.Sin(rotation),
            new Vector3(MathF.Sin(flow) * 0.47f, MathF.Cos(flow * 2f) * 0.32f, MathF.Cos(flow) * 0.39f),
            MathF.Sin(breath) * 0.014f);
    }

    public Color Sample(Vector3 normal, in Frame frame)
    {
        // Rotate the actual field over the visible hemisphere. Its large patches
        // cross the limb, while the slower deformation lets cells merge and curl.
        var point = new Vector3(normal.X * frame.CosRotation + normal.Z * frame.SinRotation,
            normal.Y, normal.Z * frame.CosRotation - normal.X * frame.SinRotation);
        var p = point * _flowScale + _offset;
        var warpA = Noise(p * 0.8f + frame.Flow, _seed);
        var warpB = Noise(p * 0.8f + frame.Flow + new Vector3(7.7f, 3.1f, 5.4f), _seed ^ 0x1fb3);
        var warped = p + new Vector3(warpA - 0.5f, warpB - 0.5f, (warpA + warpB - 1f) * 0.55f) * 1.75f;
        var cells = Noise(warped * 1.23f, _seed ^ 0x5471);
        var ribbon = 1f - MathF.Abs(Noise(warped * 0.77f + new Vector3(4.2f, 8.6f, 1.7f), _seed ^ 0x7139) - 0.5f) * 2f;
        var heat = (cells - 0.5f) * 1.55f + 0.50f + normal.Z * 0.045f + (ribbon - 0.72f) * 0.2f + frame.Breath;
        var tone = Math.Clamp((int)(heat * _palette.Length), 0, _palette.Length - 1);

        // A few continuous cream filaments and coral/cyan hollows, rather than speckles.
        if (ribbon > 0.94f && cells > 0.53f)
            tone = Math.Max(tone, cells > 0.64f ? 6 : 5);
        if (normal.Z < 0.25f)
            tone = Math.Max(1, tone - 1);
        return _palette[tone];
    }

    private static int ResolveTemperature(int value)
    {
        if (value >= 1000) return value;
        return Math.Abs(value % 7) switch
        {
            0 => 3200,
            1 => 4900,
            2 => 6500,
            3 => 8400,
            4 => 9700,
            5 => 14500,
            _ => 22000
        };
    }

    private static Color[] MakePalette(int temperature, float variation)
    {
        Color[] palette;
        if (temperature < 8000)
        {
            palette = new[]
            {
                new Color(205, 73, 97), new Color(231, 105, 90), new Color(246, 144, 98),
                new Color(255, 183, 112), new Color(255, 210, 140), new Color(255, 231, 177), new Color(255, 245, 212)
            };
            var gold = Math.Clamp((temperature - 2200f) / 9000f + variation * 0.12f, 0f, 0.72f);
            for (var i = 0; i < palette.Length; i++)
            {
                var color = palette[i];
                palette[i] = Color.Lerp(color, new Color(color.R, Math.Min(255, color.G + 25), Math.Max(0, color.B - 19)), gold);
            }
        }
        else if (temperature <= 10000)
        {
            palette = new[]
            {
                new Color(52, 128, 135), new Color(70, 162, 139), new Color(111, 193, 147),
                new Color(158, 217, 162), new Color(194, 235, 176), new Color(224, 246, 197), new Color(246, 255, 225)
            };
            var mint = Math.Clamp((temperature - 8000f) / 7000f + variation * 0.12f, 0f, 0.42f);
            for (var i = 0; i < palette.Length; i++)
            {
                var color = palette[i];
                palette[i] = Color.Lerp(color, new Color(Math.Max(0, color.R - 18), color.G, Math.Min(255, color.B + 32)), mint);
            }
        }
        else
        {
            palette = new[]
            {
                new Color(79, 101, 165), new Color(77, 141, 187), new Color(95, 184, 210),
                new Color(128, 216, 231), new Color(165, 236, 236), new Color(200, 250, 242), new Color(233, 255, 248)
            };
            var ice = Math.Clamp((temperature - 10000f) / 38000f + variation * 0.09f, 0f, 0.5f);
            for (var i = 0; i < palette.Length; i++)
            {
                var color = palette[i];
                palette[i] = Color.Lerp(color, new Color(Math.Min(255, color.R + 9), Math.Max(0, color.G - 15), Math.Min(255, color.B + 13)), ice);
            }
        }
        return palette;
    }

    private static float Noise(Vector3 point, int seed)
    {
        var x = (int)MathF.Floor(point.X);
        var y = (int)MathF.Floor(point.Y);
        var z = (int)MathF.Floor(point.Z);
        var u = Ease(point.X - x);
        var v = Ease(point.Y - y);
        var w = Ease(point.Z - z);
        var a = MathHelper.Lerp(Hash(x, y, z, seed), Hash(x + 1, y, z, seed), u);
        var b = MathHelper.Lerp(Hash(x, y + 1, z, seed), Hash(x + 1, y + 1, z, seed), u);
        var c = MathHelper.Lerp(Hash(x, y, z + 1, seed), Hash(x + 1, y, z + 1, seed), u);
        var d = MathHelper.Lerp(Hash(x, y + 1, z + 1, seed), Hash(x + 1, y + 1, z + 1, seed), u);
        return MathHelper.Lerp(MathHelper.Lerp(a, b, v), MathHelper.Lerp(c, d, v), w);
    }

    private static float Ease(float t) => t * t * t * (t * (t * 6f - 15f) + 10f);

    private static float Hash(int x, int y, int z, int seed)
    {
        unchecked
        {
            var h = (uint)seed ^ (uint)x * 0x9e3779b9u ^ (uint)y * 0x85ebca6bu ^ (uint)z * 0xc2b2ae35u;
            h ^= h >> 16;
            h *= 0x7feb352du;
            h ^= h >> 15;
            h *= 0x846ca68bu;
            h ^= h >> 16;
            return (h & 0x00ffffffu) / 16777215f;
        }
    }

    internal readonly record struct Frame(float CosRotation, float SinRotation, Vector3 Flow, float Breath);
}
