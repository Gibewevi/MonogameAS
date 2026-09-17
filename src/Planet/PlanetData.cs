using Microsoft.Xna.Framework;

namespace MonogameAS.Planet;

public sealed class PlanetData
{
    public required int[,] SurfaceCodes { get; init; }   // 10/11/12/13/20/21, -1 outside the disc
    public required int[,] CloudCodes { get; init; }     // 0/50/51
    public required PlanetPalette Palette { get; init; }
    public PlanetWorldMap? World { get; init; }
    public required int CellSize { get; init; }
    public required int WidthCells { get; init; }
    public required int HeightCells { get; init; }
    public required float OffsetX { get; init; }
    public required float OffsetY { get; init; }
    public required float RadiusPx { get; init; }
    public required Point Viewport { get; init; }
    public required int CloudCellSize { get; init; }
    public required int CloudWidthCells { get; init; }
    public required int CloudHeightCells { get; init; }
    public required float CloudOffsetX { get; init; }
    public required float CloudOffsetY { get; init; }
}
