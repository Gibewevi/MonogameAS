using System;
using System.Collections.Generic;
using Microsoft.Xna.Framework;
using MonogameAS.Galaxy;

namespace MonogameAS.Views;

// Preserve the existing galaxy's coordinates, stellar identities and exploration rules.
public partial class GalaxyView
{
    // ----------------------------- generation ------------------------------
    private void GenerateInitialGrid()
    {
        for (var tx = -StartRadius; tx <= StartRadius; tx++)
        {
            for (var ty = -StartRadius; ty <= StartRadius; ty++)
            {
                GenerateTile(new Point(tx, ty), StartColor);
            }
        }
    }

    private void GenerateNeighbors(Point center, Color color)
    {
        for (var x = center.X - 1; x <= center.X + 1; x++)
            for (var y = center.Y - 1; y <= center.Y + 1; y++)
                GenerateTile(new Point(x, y), color);
    }

    private void GenerateTile(Point tc, Color color)
    {
        if (_tiles.ContainsKey(tc))
            return;

        var density = TileDensity(tc);
        var sunsWorld = SampleTileWorld(tc, density);
        var local = new List<Vector2>(sunsWorld.Count);
        var origin = new Vector2(tc.X * TileSize, tc.Y * TileSize);
        foreach (var p in sunsWorld)
            local.Add(p - origin);

        var tile = new GalaxyTile(tc, color)
        {
            FillAlpha = MathHelper.Lerp(FillMin, FillMax, density),
            SunsLocal = local
        };

        _tiles[tc] = tile;
        _systemsCount += local.Count;
        _mapDirty = true;
    }

    private float TileDensity(Point tc)
    {
        var n = _noise.Get(tc.X, tc.Y);
        return Math.Clamp((n + 1f) * 0.5f, 0f, 1f);
    }

    private List<Vector2> SampleTileWorld(Point tc, float density)
    {
        var accepted = new List<Vector2>();
        var rng = new Pcg32(TileSeed(tc));
        var prob = Math.Clamp(density * DensityScale, 0f, 1f);
        var origin = new Vector2(tc.X * TileSize, tc.Y * TileSize);

        for (var gx = 0; gx < TileSize; gx += CandidateStep)
        {
            for (var gy = 0; gy < TileSize; gy += CandidateStep)
            {
                var basePos = origin + new Vector2(gx + CandidateStep * 0.5f, gy + CandidateStep * 0.5f);
                var p = basePos + new Vector2(
                    rng.NextFloatRange(-CandidateJitter, CandidateJitter),
                    rng.NextFloatRange(-CandidateJitter, CandidateJitter)
                );

                if (!InsideTileWithMargin(p, tc))
                    continue;
                if (rng.NextFloat() >= prob)
                    continue;
                if (SpatialTooClose(p, MinDist))
                    continue;

                SpatialAdd(p);
                accepted.Add(p);

                if (accepted.Count >= MaxSunsPerTile)
                {
                    // même comportement que le proto : pas de break obligatoire
                }
            }
        }

        return accepted;
    }

    // ----------------------------- utils -----------------------------------
    private static int SeedFromPoint(Vector2 p)
    {
        var h = (int)p.X ^ ((int)p.Y << 1);
        h ^= h << 13;
        h ^= h >> 17;
        h ^= h << 5;
        return h;
    }

    private static int ClassFromSeed(int seed) => Math.Abs(seed % 7);

    private static int TileSeed(Point tc)
    {
        var h = ((tc.X & 0xFFFF) << 16) ^ (tc.Y & 0xFFFF) ^ (WorldSeed & 0x7FFFFFFF);
        return h == 0 ? 1 : h;
    }

    private static int SunSizeFromSeed(int seed)
    {
        var rng = new Pcg32(seed ^ unchecked((int)0xA3C59AC3));
        return SunSizeOptions[rng.NextIntInclusive(0, SunSizeOptions.Length - 1)];
    }

    private static Point WorldToTile(Vector2 pos) => new(
        (int)MathF.Floor(pos.X / TileSize),
        (int)MathF.Floor(pos.Y / TileSize));

    private bool InsideTileWithMargin(Vector2 pWorld, Point tc)
    {
        var o = new Vector2(tc.X * TileSize, tc.Y * TileSize);
        return pWorld.X > o.X + BorderMargin
            && pWorld.X < o.X + TileSize - BorderMargin
            && pWorld.Y > o.Y + BorderMargin
            && pWorld.Y < o.Y + TileSize - BorderMargin;
    }

    private Point CellOf(Vector2 pWorld) => new(
        (int)MathF.Floor(pWorld.X / MinDist),
        (int)MathF.Floor(pWorld.Y / MinDist));

    private bool SpatialTooClose(Vector2 pWorld, float minDist)
    {
        var c = CellOf(pWorld);
        var min2 = minDist * minDist;
        for (var dx = -1; dx <= 1; dx++)
        {
            for (var dy = -1; dy <= 1; dy++)
            {
                var n = new Point(c.X + dx, c.Y + dy);
                if (!_spatial.TryGetValue(n, out var arr))
                    continue;
                foreach (var q in arr)
                {
                    if (Vector2.DistanceSquared(pWorld, q) < min2)
                        return true;
                }
            }
        }
        return false;
    }

    private void SpatialAdd(Vector2 pWorld)
    {
        var c = CellOf(pWorld);
        if (!_spatial.TryGetValue(c, out var arr))
        {
            arr = new List<Vector2>();
            _spatial[c] = arr;
        }
        arr.Add(pWorld);
    }

    private bool IsAdjacentToGenerated(Point coords)
    {
        if (_tiles.ContainsKey(coords))
            return true;
        for (var dx = -1; dx <= 1; dx++)
        {
            for (var dy = -1; dy <= 1; dy++)
            {
                if (dx == 0 && dy == 0) continue;
                if (_tiles.ContainsKey(new Point(coords.X + dx, coords.Y + dy)))
                    return true;
            }
        }
        return false;
    }

    // ----------------------------- inner tile type -------------------------
    private sealed class GalaxyTile
    {
        public GalaxyTile(Point coords, Color baseColor)
        {
            Coords = coords;
            BaseColor = baseColor;
        }

        public Point Coords { get; }
        public Color BaseColor { get; }
        public float FillAlpha { get; set; }
        public List<Vector2> SunsLocal { get; set; } = new();

        public Vector2 GetSunWorldPos(int id)
        {
            if (id < 0 || id >= SunsLocal.Count)
                return Vector2.Zero;
            var origin = new Vector2(Coords.X * TileSize, Coords.Y * TileSize);
            return origin + SunsLocal[id];
        }
    }


}
