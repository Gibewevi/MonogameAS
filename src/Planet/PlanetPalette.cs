using Microsoft.Xna.Framework;

namespace MonogameAS.Planet;

public readonly record struct PlanetPalette(
    Color DeepWater,
    Color ShelfWater,
    Color Beach,
    Color Plains,
    Color Hills,
    Color Mountains,
    bool HasBeaches
)
{
    public Color DryPlain { get; init; }
    public Color Desert { get; init; }
    public Color Forest { get; init; }
    public Color Snow { get; init; }
    public Color Ice { get; init; }
    public Color Glacier { get; init; }
    public Color Basalt { get; init; }
    public Color Lava { get; init; }
    public Color LavaHot { get; init; }
    public Color CraterFloor { get; init; }
    public Color CraterRim { get; init; }
    public Color SaltFlat { get; init; }
    public Color Atmosphere { get; init; }
}
