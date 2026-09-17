using Microsoft.Xna.Framework;

namespace MonogameAS.Planet;

/// <summary>
/// Paramètres de génération d'une planète (surface et nuages) partagés entre vues.
/// </summary>
public readonly record struct PlanetParams(
    int PlanetRadiusPx,
    int CellSize,
    float ElevScale,
    int ElevOctaves,
    float ElevLacunarity,
    float ElevPersistence,
    float ElevSeaLevel,
    float ElevBeachBand,
    float ElevShelfBand,
    float ElevHillLevel,
    float ElevMtnLevel,
    float CloudScale,
    float CloudThreshold,
    int CloudOctaves,
    float CloudLacunarity,
    float CloudPersistence,
    float CloudMargin,
    int CloudCellSize,
    float CloudGridMarginPx,
    Vector2 CloudSpeed
)
{
    public static PlanetParams Default => new(
        PlanetRadiusPx: 69,
        CellSize: 3,
        ElevScale: 0.09f,
        ElevOctaves: 3,
        ElevLacunarity: 2.27f,
        ElevPersistence: 0.42f,
        ElevSeaLevel: 0.42f,
        ElevBeachBand: 0.02f,
        ElevShelfBand: 0.10f,
        ElevHillLevel: 0.53f,
        ElevMtnLevel: 0.70f,
        CloudScale: 0.04f,
        CloudThreshold: 0.55f,
        CloudOctaves: 2,
        CloudLacunarity: 2.50f,
        CloudPersistence: 0.48f,
        CloudMargin: 7.15f,
        CloudCellSize: 2,
        CloudGridMarginPx: 138f,
        CloudSpeed: new Vector2(0.01f, 0.03f)
    );
}
