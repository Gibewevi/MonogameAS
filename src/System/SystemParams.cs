namespace MonogameAS.Systems;

/// <summary>
/// Paramètres de génération d'un système (orbites et planètes). Déterministe via la seed.
/// </summary>
public readonly record struct SystemParams(
    int MinPlanets,
    int MaxPlanets,
    float SemiMajorMin,
    float OrbitalSpacing,
    float EccentricityMin,
    float EccentricityMax,
    float AngularSpeedMin,
    float AngularSpeedMax,
    float PlanetRadiusMin,
    float PlanetRadiusMax,
    float CollisionGap
)
{
    public static SystemParams Default => new(
        MinPlanets: 3,
        MaxPlanets: 8,
        SemiMajorMin: 90f,
        OrbitalSpacing: 70f,
        EccentricityMin: 0.0f,
        EccentricityMax: 0.25f,
        AngularSpeedMin: 0.05f,
        AngularSpeedMax: 0.15f,
        PlanetRadiusMin: 10f,
        PlanetRadiusMax: 22f,
        CollisionGap: 12f
    );
}
