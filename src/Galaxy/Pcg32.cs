namespace MonogameAS.Galaxy;

/// <summary>
/// Simple deterministic 32-bit XorShift RNG (seeded) with helpers for float/int ranges.
/// Chosen for reproducibility; not cryptographically secure.
/// </summary>
internal sealed class Pcg32
{
    private uint _state;

    public Pcg32(int seed)
    {
        _state = seed != 0 ? (uint)seed : 1u;
    }

    private uint NextUInt()
    {
        var x = _state;
        x ^= x << 13;
        x ^= x >> 17;
        x ^= x << 5;
        _state = x;
        return x;
    }

    public float NextFloat()
    {
        // [0,1)
        return (NextUInt() & 0xFFFFFF) / 16777216f;
    }

    public int NextIntInclusive(int lo, int hi)
    {
        if (hi < lo) (lo, hi) = (hi, lo);
        var span = hi - lo + 1;
        return lo + (int)(NextUInt() % (uint)span);
    }

    public float NextFloatRange(float lo, float hi)
    {
        return lo + (hi - lo) * NextFloat();
    }
}
