using System;

namespace MonogameAS.Galaxy;

/// <summary>
/// Lightweight deterministic value noise (smooth interpolated hash grid).
/// Used in place of FastNoiseLite Simplex for density sampling.
/// </summary>
internal sealed class ValueNoise2D
{
    private readonly int _seed;

    public ValueNoise2D(int seed)
    {
        _seed = seed == 0 ? 1 : seed;
    }

    /// <summary>Frequency multiplier applied to incoming coordinates.</summary>
    public float Frequency { get; set; } = 0.08f;

    public float Get(float x, float y)
    {
        var xf = x * Frequency;
        var yf = y * Frequency;

        var xi = (int)MathF.Floor(xf);
        var yi = (int)MathF.Floor(yf);
        var tx = xf - xi;
        var ty = yf - yi;

        var v00 = Hash(xi, yi);
        var v10 = Hash(xi + 1, yi);
        var v01 = Hash(xi, yi + 1);
        var v11 = Hash(xi + 1, yi + 1);

        var u = Smooth(tx);
        var v = Smooth(ty);

        var a = Lerp(v00, v10, u);
        var b = Lerp(v01, v11, u);
        return Lerp(a, b, v); // in [-1,1]
    }

    // Hash to [-1,1]
    private float Hash(int x, int y)
    {
        unchecked
        {
            var h = x * 374761393 + y * 668265263 + _seed * 700001;
            h = (h ^ (h >> 13)) * 1274126177;
            h ^= h >> 16;
            var v = (h & 0x7fffffff) / 1073741824f; // [0,2)
            return v - 1.0f;
        }
    }

    private static float Smooth(float t) => t * t * (3f - 2f * t);

    private static float Lerp(float a, float b, float t) => a + (b - a) * t;
}
