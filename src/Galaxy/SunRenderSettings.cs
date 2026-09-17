namespace MonogameAS.Galaxy;

/// <summary>
/// Réglages globaux du rendu pixel-art des soleils.
/// CellSize est centralisé ici pour garder un standard unique.
/// </summary>
public static class SunRenderSettings
{
    /// <summary>
    /// Taille de cellule commune aux soleils galactiques à tous les zooms.
    /// </summary>
    public const int GalaxyCellSize = 2;

    /// <summary>
    /// Deux pixels logiques, comme les cellules visibles des planètes en vue système.
    /// </summary>
    public const int SystemCellSize = 2;
}
