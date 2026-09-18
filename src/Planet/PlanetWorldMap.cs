using System;
using System.Collections.Generic;
using Microsoft.Xna.Framework;

namespace MonogameAS.Planet;

/// <summary>
/// Permanent spherical surface shared by every projection. Geology, climate and
/// drainage are generated in that order; no stage selects a planet archetype.
/// </summary>
public sealed class PlanetWorldMap
{
    private const int CacheCapacity = 24;
    private static readonly object CacheLock = new();
    private static readonly Dictionary<PlanetKey, LinkedListNode<CacheEntry>> Cache = new();
    private static readonly LinkedList<CacheEntry> Recent = new();
    private readonly PlanetSurfaceCell[] _cells;
    private readonly Color[] _colors;

    public PlanetWorldMap(PlanetKey key)
    {
        Environment = key.ResolveEnvironment().Normalized();
        AtmosphereStrength = Environment.AtmosphereStrength;
        Palette = PlanetPaletteFactory.Make(Environment, key.Seed);
        // Geography survives zoom, viewport changes and different pixel sizes.
        Width = 256;
        Height = 128;
        _cells = new PlanetSurfaceCell[Width * Height];
        _colors = new Color[_cells.Length];
        new PlanetSurfaceBuilder(key, Environment, Width, Height).Build(_cells, _colors, Palette);
    }

    public PlanetEnvironment Environment { get; }
    public float AtmosphereStrength { get; }
    public PlanetPalette Palette { get; }
    public int Width { get; }
    public int Height { get; }

    public static PlanetWorldMap GetOrGenerate(PlanetKey key)
    {
        var defaults = PlanetParams.Default;
        // Legacy palette names and projection settings cannot change geography.
        key = key with
        {
            Palette = PlanetPaletteType.Standard,
            Environment = key.ResolveEnvironment().Normalized(),
            Params = key.Params with
            {
                PlanetRadiusPx = defaults.PlanetRadiusPx, CellSize = defaults.CellSize,
                CloudCellSize = defaults.CloudCellSize, CloudMargin = defaults.CloudMargin,
                CloudGridMarginPx = defaults.CloudGridMarginPx, CloudSpeed = defaults.CloudSpeed,
                CloudScale = defaults.CloudScale, CloudThreshold = defaults.CloudThreshold,
                CloudOctaves = defaults.CloudOctaves, CloudLacunarity = defaults.CloudLacunarity,
                CloudPersistence = defaults.CloudPersistence
            }
        };
        lock (CacheLock)
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
    }

    public int Sample(float longitude, float latitude) => (int)SampleCell(longitude, latitude).Terrain;
    public int SampleUv(float u, float v) => (int)SampleCellUv(u, v).Terrain;
    public PlanetSurfaceCell SampleCell(float longitude, float latitude) => _cells[Index(longitude / MathHelper.TwoPi + 0.5f, 0.5f - latitude / MathHelper.Pi)];
    public PlanetSurfaceCell SampleCellUv(float u, float v) => _cells[Index(u, v)];
    public Color SampleColor(float longitude, float latitude) => _colors[Index(longitude / MathHelper.TwoPi + 0.5f, 0.5f - latitude / MathHelper.Pi)];
    public Color SampleColorUv(float u, float v) => _colors[Index(u, v)];

    private int Index(float u, float v)
    {
        u = Finite(u, 0.5f);
        v = Finite(v, 0.5f);
        // Reflect across a pole, turning longitude halfway around the sphere.
        v %= 2f;
        if (v < 0) v += 2;
        if (v > 1) { v = 2 - v; u += 0.5f; }
        u -= MathF.Floor(u);
        var x = Math.Clamp((int)(u * Width), 0, Width - 1);
        var y = Math.Clamp((int)((1 - v) * Height), 0, Height - 1);
        return y * Width + x;
    }

    public Color ColorFor(int code) => ColorFor((PlanetTerrain)code, Palette);

    internal static Color ColorFor(PlanetTerrain terrain, PlanetPalette palette) => terrain switch
    {
        PlanetTerrain.DeepWater => palette.DeepWater,
        PlanetTerrain.ShelfWater or PlanetTerrain.River => palette.ShelfWater,
        PlanetTerrain.Beach => palette.Beach,
        PlanetTerrain.Plains => palette.Plains,
        PlanetTerrain.Hills => palette.Hills,
        PlanetTerrain.Mountains => palette.Mountains,
        PlanetTerrain.Desert => palette.Desert,
        PlanetTerrain.Forest => palette.Forest,
        PlanetTerrain.DryPlain => palette.DryPlain,
        PlanetTerrain.Snow => palette.Snow,
        PlanetTerrain.Ice => palette.Ice,
        PlanetTerrain.Glacier => palette.Glacier,
        PlanetTerrain.Basalt => palette.Basalt,
        PlanetTerrain.Lava => palette.Lava,
        PlanetTerrain.LavaHot => palette.LavaHot,
        PlanetTerrain.CraterFloor => palette.CraterFloor,
        PlanetTerrain.CraterRim => palette.CraterRim,
        PlanetTerrain.SaltFlat => palette.SaltFlat,
        _ => Color.Transparent
    };

    internal static float Finite(float value, float fallback) => float.IsFinite(value) ? value : fallback;
    private readonly record struct CacheEntry(PlanetKey Key, PlanetWorldMap World);
}
