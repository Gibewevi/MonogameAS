using System;
using Microsoft.Xna.Framework;

namespace MonogameAS.Planet;

public readonly record struct CloudFrame(int[,] Grid, int CellSize, int Width, int Height, float OffsetX, float OffsetY);

/// <summary>
/// Compatibility projection for grid consumers. The permanent spherical atlas is
/// the only terrain generator; this class only chooses which cells a view sees.
/// </summary>
public sealed class PlanetGenerator
{
    public PlanetData Generate(PlanetKey key, Point viewport, bool clipToCircle = true)
    {
        var world = PlanetWorldMap.GetOrGenerate(key);
        var p = key.Params;
        var cell = Math.Max(1, p.CellSize);
        var maximum = Math.Max(cell, (int)(Math.Min(viewport.X, viewport.Y) * 0.48f));
        var radius = Math.Max(cell, Math.Min(p.PlanetRadiusPx, maximum) / cell * cell);
        var width = radius * 2 / cell;
        var surface = new int[width, width];
        for (var y = 0; y < width; y++)
        {
            for (var x = 0; x < width; x++)
            {
                var nx = (x + 0.5f) * 2f / width - 1;
                var ny = (y + 0.5f) * 2f / width - 1;
                var square = nx * nx + ny * ny;
                if (clipToCircle && square > 1)
                {
                    surface[y, x] = -1;
                    continue;
                }
                surface[y, x] = clipToCircle
                    ? world.Sample(MathF.Atan2(nx, MathF.Sqrt(Math.Max(0, 1 - square))), MathF.Asin(-ny))
                    : world.SampleUv((x + 0.5f) / width, (y + 0.5f) / width);
            }
        }
        var clouds = GenerateCloudsFrame(key, radius, viewport, Vector2.Zero, clipToCircle);
        return new PlanetData
        {
            SurfaceCodes = surface,
            CloudCodes = clouds.Grid,
            Palette = world.Palette,
            World = world,
            CellSize = cell,
            WidthCells = width,
            HeightCells = width,
            OffsetX = (viewport.X - width * cell) / 2f,
            OffsetY = (viewport.Y - width * cell) / 2f,
            RadiusPx = radius,
            Viewport = viewport,
            CloudCellSize = clouds.CellSize,
            CloudWidthCells = clouds.Width,
            CloudHeightCells = clouds.Height,
            CloudOffsetX = clouds.OffsetX,
            CloudOffsetY = clouds.OffsetY
        };
    }

    /// <summary>Legacy family hint; new callers should supply the complete key.</summary>
    public PlanetData Generate(int seed, PlanetParams parameters, PlanetPalette palette, Point viewport, bool clipToCircle = true) =>
        Generate(new PlanetKey(seed, palette.HasBeaches ? PlanetPaletteType.Oceanic : PlanetPaletteType.Sterile, parameters), viewport, clipToCircle);

    public static CloudFrame GenerateCloudsFrame(int seed, PlanetParams parameters, int radiusPx, Point viewport, Vector2 cloudOffset, bool clipToCircle = true) =>
        GenerateCloudsFrame(new PlanetKey(seed, PlanetPaletteType.Standard, parameters), radiusPx, viewport, cloudOffset, clipToCircle);

    public static CloudFrame GenerateCloudsFrame(PlanetKey key, int radiusPx, Point viewport, Vector2 cloudOffset, bool clipToCircle = true)
    {
        var p = key.Params;
        var cell = Math.Max(1, p.CloudCellSize);
        var radius = radiusPx + (clipToCircle ? p.CloudMargin : p.CloudGridMarginPx);
        var width = Math.Max(2, (int)MathF.Ceiling(radius * 2 / cell));
        var grid = new int[width, width];
        var offsetX = (viewport.X - width * cell) / 2f;
        var offsetY = (viewport.Y - width * cell) / 2f;
        var samples = new float[width * width];
        var scale = Math.Max(0.01f, p.PlanetRadiusPx / (float)cell * p.CloudScale);
        for (var y = 0; y < width; y++)
        {
            for (var x = 0; x < width; x++)
            {
                var nx = (x + 0.5f) * 2f / width - 1;
                var ny = (y + 0.5f) * 2f / width - 1;
                var square = nx * nx + ny * ny;
                if (clipToCircle && square > 1) continue;
                var longitude = clipToCircle ? MathF.Atan2(nx, MathF.Sqrt(Math.Max(0, 1 - square))) : nx * MathHelper.Pi;
                var latitude = clipToCircle ? MathF.Asin(-ny) : -ny * MathHelper.PiOver2;
                longitude += cloudOffset.X;
                latitude += MathF.Sin(cloudOffset.Y) * 0.12f;
                var point = new Vector3(MathF.Sin(longitude) * MathF.Cos(latitude), MathF.Sin(latitude), MathF.Cos(longitude) * MathF.Cos(latitude));
                var noise = SphereNoise.Fractal(point * scale, key.Seed ^ 0x51AB7913,
                    Math.Clamp(p.CloudOctaves, 1, 4), Math.Clamp(p.CloudLacunarity, 1, 3), Math.Clamp(p.CloudPersistence, 0.1f, 0.9f));
                samples[y * width + x] = noise;
            }
        }
        var threshold = p.CloudThreshold;
        for (var y = 0; y < width; y++)
            for (var x = 0; x < width; x++)
            {
                var noise = samples[y * width + x];
                if (noise > threshold) grid[y, x] = noise > threshold + 0.13f ? 51 : 50;
            }
        return new CloudFrame(grid, cell, width, width, offsetX, offsetY);
    }
}
