using System;
using Microsoft.Xna.Framework;

namespace MonogameAS.Planet;

/// <summary>Small related color ramps, derived from chemistry and climate rather than planet classes.</summary>
public static class PlanetPaletteFactory
{
    public static PlanetPalette Make(PlanetPaletteType type, int seed) => Make(PlanetEnvironment.Generate(seed), seed);
    public static PlanetPalette MakeSterile() => MakeRandom();
    public static PlanetPalette MakeOceanic() => MakeRandom();
    public static PlanetPalette MakeStandard() => MakeRandom();

    public static PlanetPalette Make(PlanetEnvironment environment, int seed)
    {
        var e = environment.Normalized();
        float Sample(int channel) => SphereNoise.Hash(channel, 977, 223, seed);
        var warmth = Math.Clamp((e.MeanTemperatureC + 45f) / 125f, 0f, 1f);
        var hueDrift = (Sample(1) - 0.5f) * 0.045f;
        var mineralValue = 0.78f - e.Carbon * 0.28f + e.Silicates * 0.08f;
        var ironMineral = Hsv(0.035f + hueDrift * 0.5f, 0.37f + warmth * 0.05f, mineralValue);
        var silicateMineral = Hsv(0.43f + hueDrift * 0.5f, 0.22f + e.Silicates * 0.055f, mineralValue);
        var carbonMineral = Hsv(0.755f + hueDrift * 0.5f, 0.25f, mineralValue * 0.88f);
        // Continuous pigment mixing gives chemistry a visible signature. Slightly
        // emphasize dominant minerals so every mixture does not collapse into beige.
        var ironWeight = MathF.Pow(e.Iron, 1.6f);
        var silicateWeight = MathF.Pow(e.Silicates, 1.6f);
        var carbonWeight = MathF.Pow(e.Carbon * 1.3f, 1.6f);
        var weight = ironWeight + silicateWeight + carbonWeight;
        var stone = new Color((ironMineral.ToVector3() * ironWeight + silicateMineral.ToVector3() * silicateWeight
            + carbonMineral.ToVector3() * carbonWeight) / weight);
        var sand = Color.Lerp(stone, Hsv(0.12f + hueDrift, 0.36f, 0.90f), 0.44f + e.Salinity * 0.18f);
        var waterHue = 0.55f - e.Salinity * 0.06f + e.Carbon * 0.04f + hueDrift * 0.5f;
        var waterSaturation = 0.38f + e.Iron * 0.16f;
        var deep = Hsv(waterHue + 0.012f, waterSaturation + 0.1f, 0.62f + Sample(3) * 0.07f);
        var shelf = Hsv(waterHue - 0.012f, waterSaturation, 0.80f + Sample(3) * 0.04f);
        var vegetation = Hsv(0.27f + (1f - warmth) * 0.09f + hueDrift, 0.32f + e.LifePotential * 0.19f, 0.73f + Sample(4) * 0.09f);
        var plains = Color.Lerp(stone, vegetation, Math.Clamp(e.LifePotential * 1.7f, 0f, 0.92f));
        var mountains = Color.Lerp(stone, Hsv(0.66f + hueDrift, 0.2f, 0.62f), 0.43f);
        var ice = Hsv(waterHue - 0.012f, 0.21f, 0.90f);
        var snow = Color.Lerp(Hsv(waterHue, 0.08f, 0.98f), sand, 0.055f * e.Iron);
        var basalt = Color.Lerp(Hsv(0.69f + hueDrift, 0.19f, 0.40f), stone, 0.19f);
        var atmosphere = Color.Lerp(Hsv(waterHue, 0.24f, 0.91f), sand, e.Greenhouse * e.Iron * 0.72f);
        return new PlanetPalette(deep, shelf, sand, plains,
            Color.Lerp(plains, mountains, 0.52f), mountains, e.Water > 0.03f)
        {
            DryPlain = Color.Lerp(stone, sand, 0.22f),
            Desert = sand,
            Forest = Color.Lerp(vegetation, Hsv(0.40f + hueDrift, 0.44f, 0.56f), 0.35f),
            Snow = snow,
            Ice = ice,
            Glacier = Color.Lerp(ice, shelf, 0.28f),
            Basalt = basalt,
            Lava = Hsv(0.025f + e.Iron * 0.035f, 0.68f, 0.95f),
            LavaHot = Hsv(0.12f, 0.42f, 1f),
            CraterFloor = Color.Lerp(stone, basalt, 0.42f),
            CraterRim = Color.Lerp(stone, sand, 0.45f),
            SaltFlat = Color.Lerp(sand, snow, 0.65f),
            Atmosphere = atmosphere
        };
    }

    private static PlanetPalette MakeRandom()
    {
        var seed = Random.Shared.Next();
        return Make(PlanetEnvironment.Generate(seed), seed);
    }

    private static Color Hsv(float h, float s, float v)
    {
        h = (h - MathF.Floor(h)) * 6f;
        s = Math.Clamp(s, 0f, 0.8f);
        v = Math.Clamp(v, 0.25f, 1f);
        var c = v * s;
        var x = c * (1f - MathF.Abs(h % 2f - 1f));
        var m = v - c;
        var rgb = h switch
        {
            < 1f => new Vector3(c, x, 0f),
            < 2f => new Vector3(x, c, 0f),
            < 3f => new Vector3(0f, c, x),
            < 4f => new Vector3(0f, x, c),
            < 5f => new Vector3(x, 0f, c),
            _ => new Vector3(c, 0f, x)
        };
        return new Color(rgb + new Vector3(m));
    }
}
