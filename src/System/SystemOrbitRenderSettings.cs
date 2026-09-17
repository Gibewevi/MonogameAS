namespace MonogameAS.Systems;

/// <summary>
/// Runtime-adjustable orbit rendering settings for the system view.
/// </summary>
public static class SystemOrbitRenderSettings
{
    /// <summary>
    /// Orbit line thickness in pixels (0 disables orbit rendering).
    /// </summary>
    public static float OrbitThickness = 1f;

    /// <summary>
    /// Orbit line opacity in [0..1] (0 fully transparent, 1 fully opaque).
    /// </summary>
    public static float OrbitAlpha = 0.06f;
}
