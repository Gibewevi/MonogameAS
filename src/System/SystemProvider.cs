using System.Collections.Generic;
using MonogameAS.Planet;
using MonogameAS.State;

namespace MonogameAS.Systems;

/// <summary>
/// Cache système par graine, validé avec l'étoile et les paramètres de génération.
/// </summary>
public sealed class SystemProvider
{
    private readonly SystemGenerator _gen = new();
    private readonly Dictionary<int, CacheEntry> _cache = new();

    private readonly record struct CacheEntry(SunKey Sun, SystemParams SystemParams,
        PlanetParams PlanetParams, PlanetPaletteType Palette, SystemData Data);

    public void Clear()
    {
        _cache.Clear();
    }

    public void Invalidate(int seed)
    {
        _cache.Remove(seed);
    }

    public SystemData GetOrGenerate(int seed, SunKey sun, SystemParams sysParams, PlanetParams planetParams, PlanetPaletteType palette)
    {
        if (_cache.TryGetValue(seed, out var entry) && entry.Sun == sun && entry.SystemParams == sysParams
            && entry.PlanetParams == planetParams && entry.Palette == palette)
            return entry.Data;

        var generated = _gen.Generate(seed, sun, sysParams, planetParams, palette);
        _cache[seed] = new CacheEntry(sun, sysParams, planetParams, palette, generated);
        return generated;
    }
}
