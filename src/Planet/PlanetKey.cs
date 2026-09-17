namespace MonogameAS.Planet;

public enum PlanetPaletteType { Standard, Sterile, Oceanic }

public readonly record struct PlanetKey(int Seed, PlanetPaletteType Palette, PlanetParams Params)
{
    public static PlanetKey Default => new(987654321, PlanetPaletteType.Standard, PlanetParams.Default);
}
