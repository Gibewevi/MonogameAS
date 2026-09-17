using System;
using Microsoft.Xna.Framework;

namespace MonogameAS.Planet;

public static class PlanetPaletteFactory
{
    private static readonly Random SharedRng = new();

    public static PlanetPalette Make(PlanetPaletteType type, int seed)
    {
        var rng = new Random(HashSeed(seed, type));
        return type switch
        {
            PlanetPaletteType.Oceanic => MakeOceanic(rng),
            PlanetPaletteType.Sterile => MakeSterile(rng),
            PlanetPaletteType.Standard => MakeStandard(rng),
            _ => MakeStandard(rng)
        };
    }

    public static PlanetPalette MakeSterile() => MakeSterile(SharedRng);
    public static PlanetPalette MakeOceanic() => MakeOceanic(SharedRng);
    public static PlanetPalette MakeStandard() => MakeStandard(SharedRng);

    private static PlanetPalette MakeSterile(Random rng)
    {
        var fam = rng.Next(0, 5);
        float baseH = fam switch
        {
            0 => RandRange(rng, 0.02f, 0.08f),
            1 => RandRange(rng, 0.48f, 0.55f),
            2 => RandRange(rng, 0.58f, 0.64f),
            3 => RandRange(rng, 0.20f, 0.25f),
            _ => RandRange(rng, 0.78f, 0.85f)
        };
        var baseS = RandRange(rng, 0.55f, 0.75f);
        var baseV = RandRange(rng, 0.55f, 0.72f);
        var @base = ColorFromHsv(baseH, baseS, baseV);
        var plains = CapSvVariant(@base, 0f, -0.02f, 0.00f);
        var hills = CapSvVariant(@base, 0f, -0.10f, +0.01f);
        var mountains = CapSvVariant(@base, 0f, +0.06f, -0.02f);
        var shelfWater = CapSvVariant(@base, 0f, -0.15f, +0.05f);
        var deepWater = CapSvVariant(@base, 0f, -0.25f, +0.08f);
        return new PlanetPalette(
            deepWater, shelfWater,
            Beach: new Color(0.5f, 0.45f, 0.4f),
            plains, hills, mountains,
            HasBeaches: false);
    }

    private static PlanetPalette MakeOceanic(Random rng)
    {
        var baseH = RandRange(rng, 0f, 1f);
        var baseS = RandRange(rng, 0.35f, 0.7f);
        var baseV = RandRange(rng, 0.45f, 0.8f);
        var landBase = ColorFromHsv(baseH, baseS, baseV);
        var plains = Variant(landBase, 0f, -0.02f, 0f);
        var hills = Variant(landBase, 0f, -0.08f, +0.02f);
        var mountains = Variant(landBase, 0f, +0.10f, -0.05f);
        var oceanFamilies = new[]
        {
            new[] { ColorFromRgb(124, 193, 165), ColorFromRgb(112, 170, 130) },
            new[] { ColorFromRgb(124, 193, 219), ColorFromRgb(112, 170, 196) }
        };
        var choice = oceanFamilies[rng.Next(oceanFamilies.Length)];
        var shelfWater = choice[0];
        var deepWater = choice[1];
        return new PlanetPalette(
            deepWater, shelfWater,
            Beach: new Color(0.95f, 0.9f, 0.55f),
            Plains: plains,
            Hills: hills,
            Mountains: mountains,
            HasBeaches: true);
    }

    private static PlanetPalette MakeStandard(Random rng) => MakeSterile(rng);

    private static float RandRange(Random rng, float min, float max) => (float)(min + (max - min) * rng.NextDouble());
    private static Color ColorFromRgb(int r, int g, int b) => new(r / 255f, g / 255f, b / 255f);

    private static int HashSeed(int seed, PlanetPaletteType type)
    {
        unchecked
        {
            const int golden = unchecked((int)0x9E3779B9);
            const int mix = unchecked((int)0x85EBCA6B);
            var h = seed ^ golden;
            h ^= ((int)type + 1) * mix;
            h ^= h << 13;
            h ^= h >> 17;
            h ^= h << 5;
            return h == 0 ? 1 : h;
        }
    }

    private static Color ColorFromHsv(float h, float s, float v)
    {
        var hh = h * 6f;
        var c = v * s;
        var x = c * (1f - MathF.Abs(hh % 2f - 1f));
        var m = v - c;
        float rf, gf, bf;
        if (hh < 1) (rf, gf, bf) = (c, x, 0);
        else if (hh < 2) (rf, gf, bf) = (x, c, 0);
        else if (hh < 3) (rf, gf, bf) = (0, c, x);
        else if (hh < 4) (rf, gf, bf) = (0, x, c);
        else if (hh < 5) (rf, gf, bf) = (x, 0, c);
        else (rf, gf, bf) = (c, 0, x);
        return new Color(rf + m, gf + m, bf + m);
    }

    private static Color Variant(Color b, float dh, float dv, float ds = 0f)
    {
        ToHsv(b, out var h, out var s, out var v);
        return ColorFromHsv(h + dh, s + ds, v + dv);
    }

    private static Color CapSvVariant(Color b, float dh, float dv, float ds = 0f)
    {
        ToHsv(b, out var h, out var s, out var v);
        return ColorFromHsv(h + dh, Math.Clamp(s + ds, 0f, 1f), Math.Clamp(v + dv, 0f, 1f));
    }

    private static void ToHsv(Color c, out float h, out float s, out float v)
    {
        var rf = c.R / 255f;
        var gf = c.G / 255f;
        var bf = c.B / 255f;
        var max = MathF.Max(rf, MathF.Max(gf, bf));
        var min = MathF.Min(rf, MathF.Min(gf, bf));
        var delta = max - min;
        if (delta < 1e-6f) h = 0f;
        else if (max == rf) h = ((gf - bf) / delta) % 6f;
        else if (max == gf) h = (bf - rf) / delta + 2f;
        else h = (rf - gf) / delta + 4f;
        h /= 6f;
        if (h < 0) h += 1f;
        s = max < 1e-6f ? 0f : delta / max;
        v = max;
    }
}
