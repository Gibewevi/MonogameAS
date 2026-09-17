using Microsoft.Xna.Framework;

namespace MonogameAS.Planet;

/// <summary>
/// Fournit PlanetData partagé et régénéré seulement quand la clé ou le viewport changent.
/// </summary>
public sealed class PlanetProvider
{
    private readonly PlanetGenerator _generator = new();
    private PlanetData? _cached;
    private PlanetKey _cachedKey = PlanetKey.Default;
    private Point _cachedViewport;
    private bool _cachedClipToCircle = true;

    public PlanetData GetOrGenerate(PlanetKey key, Point viewport, bool clipToCircle = true)
    {
        if (_cached == null || !_cachedKey.Equals(key) || _cachedViewport != viewport || _cachedClipToCircle != clipToCircle)
        {
            var data = _generator.Generate(key, viewport, clipToCircle);
            _cached = data;
            _cachedKey = key;
            _cachedViewport = viewport;
            _cachedClipToCircle = clipToCircle;
        }

        return _cached;
    }
}
