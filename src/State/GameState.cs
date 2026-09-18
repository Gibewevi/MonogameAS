using System.Collections.Generic;
using MonogameAS.Views;

namespace MonogameAS.State;

/// <summary>
/// État global minimal pour aligner Galaxy/System (sun_key + vue courante).
/// </summary>
public sealed class GameState
{
    private readonly Dictionary<(int SystemSeed, int PlanetSeed), Planet.PlanetKey> _visitedPlanets = new();
    public ViewMode CurrentView { get; set; } = ViewMode.Galaxy;
    public SunKey SunKey { get; private set; } = SunKey.Default;
    public Planet.PlanetKey PlanetKey { get; private set; } = new(987654321, Planet.PlanetPaletteType.Oceanic, Planet.PlanetParams.Default);
    public int SystemSeed { get; private set; } = 123456789;

    public void SetSunKey(SunKey key)
    {
        SunKey = key;
    }

    public void SetPlanetKey(Planet.PlanetKey key)
    {
        PlanetKey = key;
        // Keep local terrain edits even when navigation skips the system view.
        _visitedPlanets[(SystemSeed, key.Seed)] = key;
    }

    public Planet.PlanetKey RestorePlanet(Planet.PlanetKey generated)
    {
        if (_visitedPlanets.TryGetValue((SystemSeed, generated.Seed), out var visited))
            return generated with { Params = visited.Params, Palette = visited.Palette, Environment = visited.Environment ?? generated.Environment };
        return generated;
    }

    public void SetSystemSeed(int seed)
    {
        SystemSeed = seed;
    }

}
