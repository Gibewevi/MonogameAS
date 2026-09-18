namespace MonogameAS.Planet;

/// <summary>Local surface materials, never mutually exclusive planet families.</summary>
public enum PlanetTerrain : byte
{
    Plains = 10, Beach = 11, Hills = 12, Mountains = 13,
    Desert = 14, Forest = 15, DryPlain = 16, Snow = 17,
    Ice = 18, Glacier = 19, ShelfWater = 20, DeepWater = 21,
    River = 22, Basalt = 23, Lava = 24, LavaHot = 25,
    CraterFloor = 26, CraterRim = 27, SaltFlat = 28
}

/// <summary>
/// Retained simulation fields. Elevation and moisture are normalized,
/// temperature is Celsius, geothermal heat and river flow are 0..1.
/// Crater is negative in an impact basin and positive on its raised rim.
/// </summary>
public readonly record struct PlanetSurfaceCell(
    PlanetTerrain Terrain, float Elevation, float TemperatureC, float Moisture,
    float Geothermal, float River, float Crater);
