namespace MonogameAS.State;

/// <summary>
/// Clé compacte décrivant un soleil (parité avec Godot).
/// </summary>
public readonly record struct SunKey(int Seed, int ClassId, int Celsus, int Size, int Steps)
{
    public static SunKey Default => new(123456789, 0, 0, 12, 4);
}
