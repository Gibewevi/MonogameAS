using System.Collections.Generic;
using MonogameAS.State;

namespace MonogameAS.Systems;

public sealed class SystemData
{
    public required SunKey Sun { get; init; }
    public required List<PlanetOrbital> Planets { get; init; }
    public required int Seed { get; init; }
}
