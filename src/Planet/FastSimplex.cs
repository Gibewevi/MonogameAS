using MonogameAS.Galaxy;

namespace MonogameAS.Planet;

/// <summary>
/// Petit wrapper sur ValueNoise2D pour émuler FastNoiseLite.TYPE_SIMPLEX (assez proche pour notre usage).
/// </summary>
public sealed class FastSimplex
{
    private readonly ValueNoise2D _noise;

    public FastSimplex(int seed)
    {
        _noise = new ValueNoise2D(seed) { Frequency = 1.0f };
    }

    public float Get(float x, float y) => _noise.Get(x, y);
}
