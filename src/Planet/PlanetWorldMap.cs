using System;
using System.Collections.Generic;
using Microsoft.Xna.Framework;

namespace MonogameAS.Planet;

/// <summary>
/// A permanent spherical atlas using the original elevation thresholds and
/// palettes. The system thumbnails and the close view rotate the same territory.
/// </summary>
public sealed class PlanetWorldMap
{
    private const int CacheCapacity = 24;
    private static readonly Dictionary<PlanetKey, LinkedListNode<CacheEntry>> Cache = new();
    private static readonly LinkedList<CacheEntry> Recent = new();
    private readonly byte[] _terrain;

    public PlanetWorldMap(PlanetKey key)
    {
        Palette = PlanetPaletteFactory.Make(key.Palette, key.Seed);
        Width = Math.Clamp((int)MathF.Ceiling(MathHelper.TwoPi * key.Params.PlanetRadiusPx / Math.Max(1, key.Params.CellSize)), 96, 512);
        Height = Width / 2;
        _terrain = new byte[Width * Height];
        var p = key.Params;
        var scale = Math.Max(0.01f, p.PlanetRadiusPx / (float)Math.Max(1, p.CellSize) * p.ElevScale);
        for (var y = 0; y < Height; y++)
        {
            var latitude = ((y + 0.5f) / Height - 0.5f) * MathHelper.Pi;
            var cosLatitude = MathF.Cos(latitude);
            for (var x = 0; x < Width; x++)
            {
                var longitude = ((x + 0.5f) / Width - 0.5f) * MathHelper.TwoPi;
                var point = new Vector3(MathF.Sin(longitude) * cosLatitude, MathF.Sin(latitude), MathF.Cos(longitude) * cosLatitude);
                var elevation = SphereNoise.Fractal(point * scale, key.Seed, p.ElevOctaves, p.ElevLacunarity, p.ElevPersistence);
                _terrain[y * Width + x] = Classify(elevation, p, Palette.HasBeaches);
            }
        }
    }

    public PlanetPalette Palette { get; }
    public int Width { get; }
    public int Height { get; }

    public static PlanetWorldMap GetOrGenerate(PlanetKey key)
    {
        if (Cache.TryGetValue(key, out var node))
        {
            Recent.Remove(node);
            Recent.AddFirst(node);
            return node.Value.World;
        }
        var world = new PlanetWorldMap(key);
        Cache[key] = Recent.AddFirst(new CacheEntry(key, world));
        if (Cache.Count > CacheCapacity)
        {
            var last = Recent.Last!;
            Cache.Remove(last.Value.Key);
            Recent.RemoveLast();
        }
        return world;
    }

    public int Sample(float longitude, float latitude) => SampleUv(longitude / MathHelper.TwoPi + 0.5f, 0.5f - latitude / MathHelper.Pi);

    public int SampleUv(float u, float v)
    {
        u -= MathF.Floor(u);
        var x = Math.Min(Width - 1, (int)(u * Width));
        // Atlas rows run south to north; screen-space V runs north to south.
        var y = Math.Clamp((int)((1f - v) * Height), 0, Height - 1);
        return _terrain[y * Width + x];
    }

    public Color ColorFor(int code) => code switch
    {
        21 => Palette.DeepWater,
        20 => Palette.ShelfWater,
        11 => Palette.Beach,
        10 => Palette.Plains,
        12 => Palette.Hills,
        13 => Palette.Mountains,
        _ => Color.Transparent
    };

    private static byte Classify(float elevation, PlanetParams p, bool beaches)
    {
        if (elevation < p.ElevSeaLevel - p.ElevShelfBand) return 21;
        if (elevation < p.ElevSeaLevel) return 20;
        if (elevation < p.ElevSeaLevel + p.ElevBeachBand) return beaches ? (byte)11 : (byte)10;
        if (elevation < p.ElevHillLevel) return 10;
        if (elevation < p.ElevMtnLevel) return 12;
        return 13;
    }

    private readonly record struct CacheEntry(PlanetKey Key, PlanetWorldMap World);
}

/// <summary>Small deterministic value noise; only atlas generation uses it.</summary>
internal static class SphereNoise
{
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

    private static float Ease(float value) => value * value * value * (value * (value * 6f - 15f) + 10f);

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
