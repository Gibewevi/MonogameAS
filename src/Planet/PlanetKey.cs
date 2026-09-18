namespace MonogameAS.Planet;

// Legacy editor/serialization metadata. Generation derives all appearance from Environment.
public enum PlanetPaletteType { Standard, Sterile, Oceanic }

public readonly record struct PlanetKey(int Seed, PlanetPaletteType Palette, PlanetParams Params)
{
    public PlanetEnvironment? Environment { get; init; }

    public PlanetKey(int seed, PlanetParams parameters) : this(seed, PlanetPaletteType.Standard, parameters) { }

    public PlanetEnvironment ResolveEnvironment() => Environment?.Normalized() ?? PlanetEnvironment.Generate(Seed);

    public static PlanetKey Default => new(987654321, PlanetPaletteType.Standard, PlanetParams.Default);
}
