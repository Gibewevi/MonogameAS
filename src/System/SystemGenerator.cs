using System;
using System.Collections.Generic;
using Microsoft.Xna.Framework;
using MonogameAS.Galaxy;
using MonogameAS.Planet;
using MonogameAS.State;

namespace MonogameAS.Systems;

/// <summary>
/// Génère un système solaire complet (orbites + clés planète) de façon déterministe.
/// </summary>
public sealed class SystemGenerator
{
    public SystemData Generate(int systemSeed, SunKey sun, SystemParams p, PlanetParams planetParams, PlanetPaletteType palette)
    {
        var rng = new Pcg32(systemSeed);
        var count = rng.NextIntInclusive(p.MinPlanets, p.MaxPlanets);

        var planets = new List<PlanetOrbital>(count);

        // Scene distances are layout units, not AU. Compress stellar luminosity
        // and orbital extent for an expressive, readable range of small game worlds.
        var starTemperature = sun.Celsus >= 1000 ? sun.Celsus : 3200f + Math.Clamp(sun.ClassId, 0, 6) * 1700f;
        var starSize = Math.Clamp(sun.Size / 12f, 0.5f, 2.5f);
        var luminosity = Math.Clamp(MathF.Pow(starTemperature / 5800f, 0.65f) * MathF.Pow(starSize, 0.35f), 0.65f, 1.85f);
        var orbitUnit = Math.Max(1f, p.OrbitalSpacing + (p.PlanetRadiusMin + p.PlanetRadiusMax) * 0.5f + p.CollisionGap);

        float previousA = 0f;
        float previousR = 0f;

        for (var i = 0; i < count; i++)
        {
            var semiMajor = (i == 0 ? p.SemiMajorMin : previousA + previousR + p.CollisionGap + rng.NextFloatRange(p.OrbitalSpacing * 0.8f, p.OrbitalSpacing * 1.2f));
            var ecc = rng.NextFloatRange(p.EccentricityMin, p.EccentricityMax);
            var semiMinor = semiMajor * (1f - ecc);
            var angle0 = rng.NextFloatRange(0f, MathF.Tau);
            var w = rng.NextFloatRange(p.AngularSpeedMin, p.AngularSpeedMax);
            if (rng.NextFloat() < 0.5f) w = -w;
            var radiusLogical = rng.NextFloatRange(p.PlanetRadiusMin, p.PlanetRadiusMax);

            var planetSeed = (int)HashSeeds(systemSeed, i);
            var referenceRadius = (p.PlanetRadiusMin + p.PlanetRadiusMax) * 0.5f;
            if (referenceRadius <= 0f)
                referenceRadius = 1f;
            var scaledRadius = (int)MathF.Round(planetParams.PlanetRadiusPx * (radiusLogical / referenceRadius));
            if (scaledRadius < planetParams.CellSize)
                scaledRadius = planetParams.CellSize;
            var scaledParams = planetParams with { PlanetRadiusPx = scaledRadius };
            var orbitPosition = Math.Max(0f, (semiMajor - p.SemiMajorMin) / orbitUnit);
            var orbitalDistanceAu = 0.62f + 0.5f * MathF.Log(1f + orbitPosition);
            var planetKey = new PlanetKey(planetSeed, palette, scaledParams)
            {
                Environment = PlanetEnvironment.Generate(planetSeed, orbitalDistanceAu, luminosity)
            };

            planets.Add(new PlanetOrbital
            {
                SemiMajor = semiMajor,
                SemiMinor = semiMinor,
                Angle0 = angle0,
                AngularSpeed = w,
                RadiusLogical = radiusLogical,
                PlanetKey = planetKey
            });

            previousA = semiMajor;
            previousR = radiusLogical;
        }

        return new SystemData
        {
            Sun = sun,
            Planets = planets,
            Seed = systemSeed
        };
    }

    private static long HashSeeds(int s, int i)
    {
        unchecked
        {
            var h = s ^ (i + 0x9E3779B9);
            h ^= (h << 13);
            h ^= (h >> 17);
            h ^= (h << 5);
            return h == 0 ? 1 : h;
        }
    }
}
