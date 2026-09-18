using System;
using Microsoft.Xna.Framework;

namespace MonogameAS.Planet;

/// <summary>Deterministic 3D value noise sampled on the sphere, without a UV seam.</summary>
internal static class SphereNoise
{
    // Surface validation is separate so the established cloud noise keeps its
    // original behavior for every caller-supplied octave/persistence setting.
    public static float FractalBounded(Vector3 point, int seed, int octaves, float lacunarity, float persistence) =>
        Fractal(point, seed, Math.Clamp(octaves, 1, 6),
            Math.Clamp(PlanetWorldMap.Finite(lacunarity, 2.2f), 1, 3),
            Math.Clamp(PlanetWorldMap.Finite(persistence, 0.45f), 0.05f, 0.9f));

    public static float Fractal(Vector3 point, int seed, int octaves, float lacunarity, float persistence)
    {
        var sum = 0f;
        var weight = 0f;
        var amplitude = 1f;
        point += new Vector3(13.71f, 7.93f, 25.19f);
        for (var i = 0; i < Math.Max(1, octaves); i++)
        {
            sum += Sample(point, seed) * amplitude;
            weight += amplitude;
            amplitude *= persistence;
            point *= lacunarity;
        }
        return sum / weight;
    }

    private static float Sample(Vector3 point, int seed)
    {
        var x = (int)MathF.Floor(point.X);
        var y = (int)MathF.Floor(point.Y);
        var z = (int)MathF.Floor(point.Z);
        var fx = Ease(point.X - x);
        var fy = Ease(point.Y - y);
        var fz = Ease(point.Z - z);
        var a = MathHelper.Lerp(Hash(x, y, z, seed), Hash(x + 1, y, z, seed), fx);
        var b = MathHelper.Lerp(Hash(x, y + 1, z, seed), Hash(x + 1, y + 1, z, seed), fx);
        var c = MathHelper.Lerp(Hash(x, y, z + 1, seed), Hash(x + 1, y, z + 1, seed), fx);
        var d = MathHelper.Lerp(Hash(x, y + 1, z + 1, seed), Hash(x + 1, y + 1, z + 1, seed), fx);
        return MathHelper.Lerp(MathHelper.Lerp(a, b, fy), MathHelper.Lerp(c, d, fy), fz);
    }

    private static float Ease(float value) => value * value * value * (value * (value * 6 - 15) + 10);

    internal static float Hash(int x, int y, int z, int seed)
    {
        unchecked
        {
            var h = (uint)seed ^ (uint)x * 0x9E3779B9u ^ (uint)y * 0x85EBCA6Bu ^ (uint)z * 0xC2B2AE35u;
            h ^= h >> 16;
            h *= 0x7FEB352Du;
            h ^= h >> 15;
            h *= 0x846CA68Bu;
            h ^= h >> 16;
            return (h & 0xFFFFFFu) / 16777215f;
        }
    }
}
