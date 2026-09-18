using System;

namespace MonogameAS.Planet;

/// <summary>
/// Continuous, deterministic world traits. Temperatures and pressure are artistic
/// approximations: the relationships stay coherent without attempting a climate simulation.
/// Water is an inventory, so frozen water remains available for local melting.
/// </summary>
public readonly record struct PlanetEnvironment
{
    public PlanetEnvironment() { }

    public float OrbitalDistanceAu { get; init; } = 1f;
    public float StellarLuminosity { get; init; } = 1f;
    public float Atmosphere { get; init; } = 0.72f;
    public float Greenhouse { get; init; } = 0.48f;
    public float Water { get; init; } = 0.58f;
    public float Salinity { get; init; } = 0.2f;
    public float Volcanism { get; init; } = 0.2f;
    public float Tectonics { get; init; } = 0.5f;
    public float AgeGyr { get; init; } = 4.5f;
    public float Impacts { get; init; } = 0.2f;
    public float Erosion { get; init; } = 0.5f;
    public float AxialTilt { get; init; } = 23.4f;
    public float Iron { get; init; } = 0.28f;
    public float Silicates { get; init; } = 0.64f;
    public float Carbon { get; init; } = 0.08f;
    public float LifePotential { get; init; } = 0.65f;
    public float ContinentalScale { get; init; } = 2.1f;
    public float Relief { get; init; } = 0.5f;

    public float MeanTemperatureC
    {
        get
        {
            var e = Normalized();
            var irradiation = e.StellarLuminosity / (e.OrbitalDistanceAu * e.OrbitalDistanceAu);
            var equilibrium = 255f * MathF.Pow(irradiation, 0.25f) - 273.15f;
            return Math.Clamp(equilibrium + e.Atmosphere * (12f + 65f * e.Greenhouse) + e.Volcanism * 7f, -240f, 700f);
        }
    }

    /// <summary>Pressure and evaporation limit exposed liquid; local cold is handled by the atlas.</summary>
    public float LiquidWaterPotential
    {
        get
        {
            var e = Normalized();
            var pressure = Smooth(0.025f, 0.19f, e.Atmosphere);
            var boiling = 65f + e.Atmosphere * 95f;
            return pressure * (1f - Smooth(boiling - 15f, boiling + 70f, e.MeanTemperatureC));
        }
    }

    public float AtmosphereStrength => Smooth(0.025f, 0.85f, Normalized().Atmosphere);

    public PlanetEnvironment Normalized()
    {
        var iron = Unit(Iron);
        var silicates = Unit(Silicates);
        var carbon = Unit(Carbon);
        var total = iron + silicates + carbon;
        if (total < 0.0001f) { iron = 0.28f; silicates = 0.64f; carbon = 0.08f; total = 1f; }
        // Avoid float-rounding drift when an already normalized key is revisited.
        var compositionDivisor = MathF.Abs(total - 1f) < 0.000001f ? 1f : total;
        return this with
        {
            OrbitalDistanceAu = FiniteClamp(OrbitalDistanceAu, 0.12f, 20f, 1f),
            StellarLuminosity = FiniteClamp(StellarLuminosity, 0.02f, 20f, 1f),
            Atmosphere = Unit(Atmosphere), Greenhouse = Unit(Greenhouse),
            Water = Unit(Water), Salinity = Unit(Salinity),
            Volcanism = Unit(Volcanism), Tectonics = Unit(Tectonics),
            AgeGyr = FiniteClamp(AgeGyr, 0.02f, 12f, 4.5f),
            Impacts = Unit(Impacts), Erosion = Unit(Erosion),
            AxialTilt = FiniteClamp(AxialTilt, 0f, 90f, 23.4f),
            Iron = iron / compositionDivisor, Silicates = silicates / compositionDivisor, Carbon = carbon / compositionDivisor,
            LifePotential = Unit(LifePotential),
            ContinentalScale = FiniteClamp(ContinentalScale, 0.7f, 5f, 2.1f),
            Relief = Unit(Relief)
        };
    }

    public static PlanetEnvironment Generate(int seed, float? orbitalDistanceAu = null, float stellarLuminosity = 1f)
    {
        // Independent channels make adding a trait leave all other samples stable.
        float Sample(int channel) => SphereNoise.Hash(channel, 419, 761, seed);
        var age = 0.02f + 11.98f * MathF.Pow(Sample(1), 1.55f);
        var volcanism = Math.Clamp((0.12f + Sample(2) * 1.2f) * MathF.Exp(-age / 7f), 0f, 1f);
        var atmosphere = Math.Clamp(0.015f + MathF.Pow(Sample(3), 0.85f) * 0.88f + volcanism * 0.10f, 0f, 1f);
        var water = MathF.Pow(Sample(4), 1.25f);
        var tectonics = Math.Clamp(0.08f + volcanism * 0.45f + water * 0.18f + Sample(5) * 0.36f, 0f, 1f);
        var e = new PlanetEnvironment
        {
            OrbitalDistanceAu = orbitalDistanceAu ?? MathF.Exp(MathF.Log(0.62f) + Sample(6) * MathF.Log(2.1f / 0.62f)),
            StellarLuminosity = stellarLuminosity,
            Atmosphere = atmosphere,
            Greenhouse = Math.Clamp(0.12f + Sample(7) * 0.68f + volcanism * 0.18f, 0f, 1f),
            Water = water,
            Salinity = Sample(8) * (0.65f + 0.35f * (1f - water)),
            Volcanism = volcanism,
            Tectonics = tectonics,
            AgeGyr = age,
            Impacts = Math.Clamp((0.12f + Sample(9) * 0.8f) * (0.35f + 0.65f * (1f - atmosphere)) * (0.3f + age / 15f), 0f, 1f),
            Erosion = Math.Clamp((0.1f + Sample(10) * 0.45f + water * atmosphere * 0.6f) * (0.25f + age / 12f), 0f, 1f),
            AxialTilt = 3f + MathF.Pow(Sample(11), 1.5f) * 65f,
            Iron = 0.06f + Sample(12) * 0.72f,
            Silicates = 0.18f + Sample(13) * 0.85f,
            Carbon = 0.015f + MathF.Pow(Sample(14), 1.7f) * 0.4f,
            ContinentalScale = 0.8f + Sample(15) * 3.8f,
            Relief = Math.Clamp(0.16f + tectonics * 0.48f + Sample(16) * 0.38f, 0f, 1f)
        }.Normalized();
        // This is a potential, not a verdict for the whole planet. Local climate
        // decides where it is expressed, including sheltered/geothermal refuges.
        return e with { LifePotential = (0.2f + Sample(17) * 0.8f) * MathF.Sqrt(water * atmosphere) * Smooth(0.1f, 1.6f, age) };
    }

    private static float Unit(float value) => FiniteClamp(value, 0f, 1f, 0f);
    private static float FiniteClamp(float value, float min, float max, float fallback) => float.IsFinite(value) ? Math.Clamp(value, min, max) : fallback;
    private static float Smooth(float start, float end, float value)
    {
        var t = Math.Clamp((value - start) / (end - start), 0f, 1f);
        return t * t * (3f - 2f * t);
    }
}
