using Microsoft.Xna.Framework.Graphics;

namespace MonogameAS.Galaxy;

/// <summary>
/// Pair of textures baked for a sun (albedo + halo).
/// </summary>
internal sealed record SunTextures(Texture2D Albedo, Texture2D Halo);
