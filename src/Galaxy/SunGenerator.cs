using System;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace MonogameAS.Galaxy;

/// <summary>
/// Static LOD of the same flowing plasma model used in the system view. The
/// legacy steps argument remains for cache/API compatibility, not cellular passes.
/// </summary>
internal static class SunGenerator
{
    public static SunTextures Bake(GraphicsDevice device, int seed, int classId, int texSize, int steps,
        int cellSizePx = SunRenderSettings.GalaxyCellSize)
    {
        texSize = Math.Clamp(texSize, 1, 256);
        // Fewer than four cells across put every cell centre inside the disc,
        // producing a solid square. Tiny distant stars need one-pixel cells
        // to retain stepped, round silhouettes without enlarging or smoothing.
        var cell = Math.Clamp(cellSizePx, 1, Math.Max(1, texSize / 4));
        var tiles = Math.Max(1, texSize / cell);
        var offset = (texSize - tiles * cell) / 2;
        var plasma = new SolarPlasmaModel(seed, classId);
        var frame = plasma.At(0);
        var colors = new Color[texSize * texSize];
        for (var y = 0; y < tiles; y++)
        for (var x = 0; x < tiles; x++)
        {
            var nx = (x + 0.5f) * 2f / tiles - 1f;
            var ny = (y + 0.5f) * 2f / tiles - 1f;
            var radiusSquared = nx * nx + ny * ny;
            if (radiusSquared > 1f) continue;
            var normal = new Vector3(nx, -ny, MathF.Sqrt(1f - radiusSquared));
            var color = plasma.Sample(normal, frame);
            for (var oy = 0; oy < cell; oy++)
            for (var ox = 0; ox < cell; ox++)
                colors[(offset + y * cell + oy) * texSize + offset + x * cell + ox] = color;
        }

        var albedo = new Texture2D(device, texSize, texSize);
        albedo.SetData(colors);
        // The tiny galaxy texture bounds contain the disc itself. Keeping this
        // companion transparent avoids clipping a corona at the sprite boundary.
        var halo = new Texture2D(device, texSize, texSize);
        halo.SetData(new Color[texSize * texSize]);
        return new SunTextures(albedo, halo);
    }
}
