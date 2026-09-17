using MonogameAS.Planet;

namespace MonogameAS.Systems;

public sealed class PlanetOrbital
{
    public required float SemiMajor;
    public required float SemiMinor;
    public required float Angle0;
    public required float AngularSpeed;
    public required float RadiusLogical;
    public required PlanetKey PlanetKey;
}
