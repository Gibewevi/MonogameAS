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
);
