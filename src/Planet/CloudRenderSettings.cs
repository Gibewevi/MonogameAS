using Microsoft.Xna.Framework;

namespace MonogameAS.Planet;

/// <summary>
/// Couleurs des nuages alignées sur Godot.
/// </summary>
public static class CloudRenderSettings
{
    public static readonly Color BaseLight = new(1f, 1f, 1f, 1f);   // code 50
    public static readonly Color BaseDark = new(1f, 1f, 1f, 1f);    // code 51 (blanc aussi)

    public static float LightAlpha = 0.83f;
    public static float DarkAlpha = 0.58f;

    public static Color Light => new(BaseLight.R / 255f, BaseLight.G / 255f, BaseLight.B / 255f, LightAlpha);
    public static Color Dark => new(BaseDark.R / 255f, BaseDark.G / 255f, BaseDark.B / 255f, DarkAlpha);
}
