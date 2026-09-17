using System;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace MonogameAS.Planet;

/// <summary>
/// Point-sampled globe, with a rotating atlas and quantized spherical lighting.
/// Projection tables and pixel buffers are retained; texture uploads run at 12 Hz.
/// </summary>
internal sealed class PixelPlanetRenderer : IDisposable
{
    private readonly GraphicsDevice _device;
    private PlanetKey _key;
    private bool _ready;
    private bool _clip;
    private Point _viewport;
    private PlanetWorldMap _world = null!;
    private Layer _surface = null!;
    private Layer _clouds = null!;
    private Layer _atmosphere = null!;
    private Texture2D? _ringBack;
    private Texture2D? _ringFront;
    private Color[] _ringBackPixels = Array.Empty<Color>();
    private Color[] _ringFrontPixels = Array.Empty<Color>();
    private RingPixel[] _ringPixels = Array.Empty<RingPixel>();
    private float[] _cloudMap = Array.Empty<float>();
    private readonly Moon[] _moons = new Moon[3];
    private double _lastFrame = double.NegativeInfinity;
    private double _previousTime;
    private double _cloudTime;
    private double _time;
    private bool _cloudActive;
    private float _ringTilt;
    private float _ringCos;
    private float _ringSin;
    private float _ringInclination;
    private int _ringSize;
    private Vector3 _ringNormal;
    private int _lastSettings;

    public PixelPlanetRenderer(GraphicsDevice device) => _device = device;

    public Vector2 Center { get; private set; }
    public float Radius { get; private set; }
    public int RingCount { get; private set; }
    public int MoonCount { get; private set; }

    public void Update(PlanetKey key, Point viewport, double seconds, Vector3 lightDirection, Color sunlight,
        bool clipToCircle, bool cloudsActive, bool cloudsMove, int rings = -1, int moons = -1)
    {
        var ringCount = rings < 0 ? (int)((uint)key.Seed / 7u % 4u) : rings;
        var moonCount = moons < 0 ? 1 + (int)((uint)key.Seed / 11u % 2u) : moons;
        var rebuild = !_ready || key != _key || viewport != _viewport || clipToCircle != _clip || ringCount != RingCount || moonCount != MoonCount;
        if (rebuild)
            Configure(key, viewport, clipToCircle, ringCount, moonCount);

        var elapsed = Math.Clamp(seconds - _previousTime, 0, 0.25);
        if (cloudsActive && cloudsMove)
            _cloudTime += elapsed;
        _previousTime = seconds;
        _time = seconds;
        _cloudActive = cloudsActive;
        var settings = HashCode.Combine(cloudsActive, cloudsMove, CloudRenderSettings.LightAlpha, CloudRenderSettings.DarkAlpha);
        if (!rebuild && settings == _lastSettings && seconds - _lastFrame < 1.0 / 12.0)
            return;
        _lastFrame = seconds;
        _lastSettings = settings;

        var rotation = (float)(seconds / 84.0 % 1.0);
        UpdateSurface(rotation, lightDirection, sunlight);
        UpdateClouds(rotation, lightDirection, sunlight);
        UpdateAtmosphere(lightDirection, sunlight);
        UpdateRings(lightDirection, sunlight);
        for (var i = 0; i < MoonCount; i++)
            _moons[i].Update(lightDirection, sunlight);
    }

    private void Configure(PlanetKey key, Point viewport, bool clip, int rings, int moons)
    {
        var newWorld = !_ready || key != _key;
        if (newWorld)
        {
            _world = PlanetWorldMap.GetOrGenerate(key);
            _cloudMap = new float[_world.Width * _world.Height];
            GenerateCloudAtlas(key);
        }
        DisposeGeometry();
        _key = key;
        _viewport = viewport;
        _clip = clip;
        RingCount = Math.Clamp(rings, 0, 3);
        MoonCount = Math.Clamp(moons, 0, 3);
        var cell = Math.Max(1, key.Params.CellSize);
        var outerExtent = MoonCount > 0 ? 2.10f + (MoonCount - 1) * 0.32f : RingCount > 0 ? 1.92f : 1.16f;
        var maximum = Math.Min(viewport.X * 0.46f / outerExtent, viewport.Y * 0.37f);
        Radius = Math.Max(cell * 2, MathF.Min(key.Params.PlanetRadiusPx, maximum));
        Radius = Math.Max(cell * 2, MathF.Floor(Radius / cell) * cell);
        Center = new Vector2(viewport.X / 2, viewport.Y / 2 + 12);
        _surface = new Layer(_device, Radius, cell, clip);
        var cloudRadius = Radius + key.Params.CloudMargin;
        if (!clip)
            cloudRadius = Radius + Math.Min(key.Params.CloudGridMarginPx, Math.Max(viewport.X, viewport.Y) / 2f);
        _clouds = new Layer(_device, cloudRadius, Math.Max(1, key.Params.CloudCellSize), clip);
        _atmosphere = new Layer(_device, Radius + Math.Max(4, cell * 2), Math.Max(1, Math.Min(2, cell)), true);

        _ringTilt = -0.23f + SphereNoise.Hash(0, 0, 2, key.Seed) * 0.12f;
        _ringCos = MathF.Cos(_ringTilt);
        _ringSin = MathF.Sin(_ringTilt);
        _ringInclination = 0.32f + SphereNoise.Hash(0, 0, 3, key.Seed) * 0.09f;
        var slope = MathF.Sqrt(1 - _ringInclination * _ringInclination);
        _ringNormal = new Vector3(_ringSin * slope, -_ringCos * slope, _ringInclination);
        BuildRings();
        for (var i = 0; i < MoonCount; i++)
            _moons[i] = new Moon(_device, key.Seed + i * 3719, i, Radius, _world.Palette);
        _ready = true;
    }

    private void GenerateCloudAtlas(PlanetKey key)
    {
        var p = key.Params;
        var scale = Math.Max(0.01f, p.PlanetRadiusPx / (float)Math.Max(1, p.CloudCellSize) * p.CloudScale);
        for (var y = 0; y < _world.Height; y++)
        {
            var latitude = (0.5f - (y + 0.5f) / _world.Height) * MathHelper.Pi;
            var cosLatitude = MathF.Cos(latitude);
            for (var x = 0; x < _world.Width; x++)
            {
                var longitude = ((x + 0.5f) / _world.Width - 0.5f) * MathHelper.TwoPi;
                var point = new Vector3(MathF.Sin(longitude) * cosLatitude, MathF.Sin(latitude), MathF.Cos(longitude) * cosLatitude);
                var density = SphereNoise.Fractal(point * scale, key.Seed ^ 0x51AB7913, p.CloudOctaves, p.CloudLacunarity, p.CloudPersistence);
                _cloudMap[y * _world.Width + x] = density;
            }
        }
    }

    private float CloudSample(float u, float v)
    {
        u += (float)(_cloudTime * _key.Params.CloudSpeed.X * 0.22) + _key.Params.CloudGridMarginPx * 0.0002f;
        // Slow latitude drift oscillates through the poles instead of wrapping a hard seam.
        v += MathF.Sin((float)(_cloudTime * _key.Params.CloudSpeed.Y * 0.28)) * 0.12f;
        if (v < 0) { v = -v; u += 0.5f; }
        if (v > 1) { v = 2 - v; u += 0.5f; }
        u -= MathF.Floor(u);
        var x = Math.Min(_world.Width - 1, (int)(u * _world.Width));
        var y = Math.Clamp((int)(v * _world.Height), 0, _world.Height - 1);
        return _cloudMap[y * _world.Width + x];
    }

    private void UpdateSurface(float rotation, Vector3 light, Color sunlight)
    {
        for (var i = 0; i < _surface.Pixels.Length; i++)
        {
            if (!_surface.Valid[i]) continue;
            var normal = _surface.Normals[i];
            var uv = _surface.Uv[i];
            var code = _world.SampleUv(uv.X + rotation, uv.Y);
            var color = Shade(_world.ColorFor(code), normal, light, sunlight);
            if (_cloudActive && CloudSample(uv.X + rotation - light.X * 0.016f, uv.Y - light.Y * 0.012f) > _key.Params.CloudThreshold + 0.055f)
                color = Color.Lerp(color, new Color(21, 29, 52), 0.14f);
            if (_clip && RingCount > 0 && Vector3.Dot(normal, light) > 0 && IsRingShadow(normal, light))
                color = Color.Lerp(color, new Color(15, 20, 36), 0.32f);
            _surface.Pixels[i] = color;
        }
        _surface.Upload();
    }

    private void UpdateClouds(float rotation, Vector3 light, Color sunlight)
    {
        for (var i = 0; i < _clouds.Pixels.Length; i++)
        {
            _clouds.Pixels[i] = Color.Transparent;
            if (!_cloudActive || !_clouds.Valid[i]) continue;
            var uv = _clouds.Uv[i];
            var elevation = CloudSample(uv.X + rotation, uv.Y);
            if (elevation <= _key.Params.CloudThreshold) continue;
            var normal = _clouds.Normals[i];
            var dense = elevation > _key.Params.CloudThreshold + 0.13f;
            var baseColor = dense ? new Color(218, 229, 238) : new Color(249, 245, 234);
            var color = Shade(baseColor, normal, light, sunlight);
            var alpha = dense ? CloudRenderSettings.DarkAlpha : CloudRenderSettings.LightAlpha;
            alpha *= normal.Z < 0.24f ? 0.57f : 0.82f;
            _clouds.Pixels[i] = color * alpha;
        }
        _clouds.Upload();
    }

    private void UpdateAtmosphere(Vector3 light, Color sunlight)
    {
        for (var i = 0; i < _atmosphere.Pixels.Length; i++)
        {
            _atmosphere.Pixels[i] = Color.Transparent;
            if (!_clip || !_atmosphere.Valid[i]) continue;
            var normal = _atmosphere.Normals[i];
            var radial = MathF.Sqrt(normal.X * normal.X + normal.Y * normal.Y) * _atmosphere.Radius;
            if (radial < Radius - 1) continue;
            var rimLight = Math.Max(0, Vector3.Dot(new Vector3(normal.X, normal.Y, 0.16f), light));
            var inner = radial < Radius + 2;
            var alpha = (inner ? 0.30f : 0.07f) * (0.35f + rimLight * 0.9f);
            var tint = Color.Lerp(new Color(102, 152, 193), sunlight, rimLight * 0.30f);
            _atmosphere.Pixels[i] = tint * alpha;
        }
        _atmosphere.Upload();
    }

    private void BuildRings()
    {
        const int cell = 2;
        _ringSize = (int)MathF.Ceiling(Radius * 3.9f / cell);
        _ringBack = new Texture2D(_device, _ringSize, _ringSize);
        _ringFront = new Texture2D(_device, _ringSize, _ringSize);
        _ringBackPixels = new Color[_ringSize * _ringSize];
        _ringFrontPixels = new Color[_ringSize * _ringSize];
        var pixels = new System.Collections.Generic.List<RingPixel>();
        for (var y = 0; y < _ringSize; y++)
        {
            for (var x = 0; x < _ringSize; x++)
            {
                var px = ((x + 0.5f) * cell - _ringSize * cell / 2f) / Radius;
                var py = ((y + 0.5f) * cell - _ringSize * cell / 2f) / Radius;
                var localX = px * _ringCos + py * _ringSin;
                var localY = -px * _ringSin + py * _ringCos;
                var planeY = localY / _ringInclination;
                var radial = MathF.Sqrt(localX * localX + planeY * planeY);
                var band = RingBand(radial);
                if (band < 0) continue;
                var noise = SphereNoise.Hash(x / 2, y / 2, band, _key.Seed);
                if (noise < 0.045f) continue;
                var z = planeY * MathF.Sqrt(1 - _ringInclination * _ringInclination);
                var front = z > 0;
                var point = new Vector3(px, py, z);
                var stripe = (int)((radial - 1.24f) * 72f) % 4;
                pixels.Add(new RingPixel(y * _ringSize + x, point, front, band, stripe, noise));
            }
        }
        _ringPixels = pixels.ToArray();
    }

    private int RingBand(float radius)
    {
        for (var i = 0; i < RingCount; i++)
        {
            var inner = 1.24f + i * 0.22f;
            if (radius >= inner && radius <= inner + (i == 0 ? 0.15f : 0.12f)) return i;
        }
        return -1;
    }

    private bool IsRingShadow(Vector3 surface, Vector3 light)
    {
        var denominator = Vector3.Dot(_ringNormal, light);
        if (MathF.Abs(denominator) < 0.02f) return false;
        var distance = -Vector3.Dot(_ringNormal, surface) / denominator;
        if (distance < 0) return false;
        var hit = surface + light * distance;
        var localX = hit.X * _ringCos + hit.Y * _ringSin;
        var localY = (-hit.X * _ringSin + hit.Y * _ringCos) / _ringInclination;
        return RingBand(MathF.Sqrt(localX * localX + localY * localY)) >= 0;
    }

    private void UpdateRings(Vector3 light, Color sunlight)
    {
        var peach = Color.Lerp(new Color(203, 164, 156), _world.Palette.Beach, 0.26f);
        var ice = Color.Lerp(new Color(151, 177, 193), _world.Palette.ShelfWater, 0.20f);
        foreach (var pixel in _ringPixels)
        {
            var color = Color.Lerp(pixel.Band % 2 == 0 ? peach : ice, sunlight, 0.13f);
            var strength = (pixel.Front ? 0.83f : 0.48f) + pixel.Stripe * 0.035f;
            var towardLight = Vector3.Dot(pixel.Position, light);
            var closest = pixel.Position - light * towardLight;
            if (towardLight < 0 && closest.LengthSquared() < 1.02f)
                strength *= 0.36f;
            color *= strength * (0.83f + pixel.Noise * 0.17f);
            if (pixel.Front) _ringFrontPixels[pixel.Index] = color;
            else _ringBackPixels[pixel.Index] = color;
        }
        _ringBack!.SetData(_ringBackPixels);
        _ringFront!.SetData(_ringFrontPixels);
    }

    public void Draw(SpriteBatch spriteBatch, Texture2D pixel)
    {
        if (!_ready) return;
        DrawMoons(spriteBatch, false);
        var ringRect = new Rectangle((int)Center.X - _ringSize, (int)Center.Y - _ringSize, _ringSize * 2, _ringSize * 2);
        if (RingCount > 0) spriteBatch.Draw(_ringBack!, ringRect, Color.White);
        _atmosphere.Draw(spriteBatch, Center);
        _surface.Draw(spriteBatch, Center);
        if (_cloudActive) _clouds.Draw(spriteBatch, Center);
        if (RingCount > 0) spriteBatch.Draw(_ringFront!, ringRect, Color.White);
        DrawMoons(spriteBatch, true);
    }

    private void DrawMoons(SpriteBatch spriteBatch, bool front)
    {
        // The sign of depth is taken before the ellipse is tilted on screen.
        // It changes only at the unobscured ends of the orbit, so no moon pops.
        for (var i = MoonCount - 1; i >= 0; i--)
        {
            var moon = _moons[i];
            var phase = (float)(_time * (0.14f - i * 0.028f) + moon.Phase);
            var sin = MathF.Sin(phase);
            if ((sin >= 0) != front) continue;
            var x = MathF.Cos(phase) * Radius * (1.95f + i * 0.32f);
            var y = sin * Radius * (0.36f + i * 0.07f);
            var position = Center + new Vector2(x * _ringCos - y * _ringSin, x * _ringSin + y * _ringCos);
            moon.Draw(spriteBatch, position);
        }
    }

    internal static Color Shade(Color albedo, Vector3 normal, Vector3 light, Color sunlight)
    {
        var illumination = Vector3.Dot(normal, light);
        // A few deliberately visible tonal steps retain the little pixel-grid look.
        var brightness = illumination switch
        {
            < -0.18f => 0.22f,
            < -0.04f => 0.30f,
            < 0.08f => 0.44f,
            < 0.25f => 0.63f,
            < 0.52f => 0.83f,
            _ => 1f
        };
        var edge = normal.Z < 0.22f ? 0.81f : normal.Z < 0.48f ? 0.93f : 1f;
        var color = Color.Lerp(new Color(15, 20, 39), albedo, brightness * edge);
        if (illumination > 0.08f)
            color = Color.Lerp(color, sunlight, 0.035f + Math.Max(0, illumination) * 0.055f);
        return color;
    }

    private void DisposeGeometry()
    {
        _surface?.Dispose();
        _clouds?.Dispose();
        _atmosphere?.Dispose();
        _ringBack?.Dispose();
        _ringFront?.Dispose();
        foreach (var moon in _moons) moon?.Dispose();
        Array.Clear(_moons);
    }

    public void Dispose() => DisposeGeometry();

    private readonly record struct RingPixel(int Index, Vector3 Position, bool Front, int Band, int Stripe, float Noise);

    private sealed class Layer : IDisposable
    {
        public readonly Texture2D Texture;
        public readonly Color[] Pixels;
        public readonly Vector3[] Normals;
        public readonly Vector2[] Uv;
        public readonly bool[] Valid;
        public readonly int Cell;
        public readonly int Size;
        public readonly float Radius;

        public Layer(GraphicsDevice device, float radius, int cell, bool clip)
        {
            Cell = cell;
            Size = Math.Max(2, (int)MathF.Ceiling(radius * 2 / cell));
            Radius = Size * cell / 2f;
            Texture = new Texture2D(device, Size, Size);
            Pixels = new Color[Size * Size];
            Normals = new Vector3[Pixels.Length];
            Uv = new Vector2[Pixels.Length];
            Valid = new bool[Pixels.Length];
            for (var y = 0; y < Size; y++)
            {
                for (var x = 0; x < Size; x++)
                {
                    var i = y * Size + x;
                    var nx = ((x + 0.5f) / Size - 0.5f) * 2;
                    var ny = ((y + 0.5f) / Size - 0.5f) * 2;
                    var squared = nx * nx + ny * ny;
                    if (clip && squared > 1) continue;
                    Valid[i] = true;
                    var nz = MathF.Sqrt(Math.Max(0.001f, 1 - squared));
                    Normals[i] = Vector3.Normalize(new Vector3(nx, ny, nz));
                    Uv[i] = clip
                        ? new Vector2(MathF.Atan2(nx, nz) / MathHelper.TwoPi + 0.5f, MathF.Asin(ny) / MathHelper.Pi + 0.5f)
                        : new Vector2((x + 0.5f) / Size, (y + 0.5f) / Size);
                }
            }
        }

        public void Upload() => Texture.SetData(Pixels);

        public void Draw(SpriteBatch batch, Vector2 center)
        {
            var diameter = Size * Cell;
            batch.Draw(Texture, new Rectangle((int)center.X - diameter / 2, (int)center.Y - diameter / 2, diameter, diameter), Color.White);
        }

        public void Dispose() => Texture.Dispose();
    }

    private sealed class Moon : IDisposable
    {
        private readonly Layer _layer;
        private readonly Color[] _albedo;
        public readonly float Phase;

        public Moon(GraphicsDevice device, int seed, int index, float planetRadius, PlanetPalette palette)
        {
            var radius = Math.Clamp(planetRadius * (0.125f - index * 0.014f), 4, 12);
            _layer = new Layer(device, radius, 2, true);
            _albedo = new Color[_layer.Pixels.Length];
            Phase = 0.7f + SphereNoise.Hash(0, 0, index, seed) * MathHelper.TwoPi;
            var tint = Color.Lerp(index % 2 == 0 ? new Color(205, 190, 196) : new Color(179, 198, 203), palette.Hills, 0.16f);
            var crater1 = new Vector2(-0.28f, -0.26f);
            var crater2 = new Vector2(0.35f, 0.29f);
            for (var i = 0; i < _albedo.Length; i++)
            {
                var normal = _layer.Normals[i];
                var noise = SphereNoise.Hash(i % _layer.Size / 2, i / _layer.Size / 2, 0, seed);
                var color = Color.Lerp(tint, new Color(112, 108, 138), noise > 0.57f ? 0.25f : 0.07f);
                var pos = new Vector2(normal.X, normal.Y);
                if (Vector2.DistanceSquared(pos, crater1) < 0.045f || Vector2.DistanceSquared(pos, crater2) < 0.028f)
                    color = Color.Lerp(color, new Color(96, 91, 121), 0.43f);
                _albedo[i] = color;
            }
        }

        public void Update(Vector3 light, Color sunlight)
        {
            for (var i = 0; i < _albedo.Length; i++)
                if (_layer.Valid[i]) _layer.Pixels[i] = Shade(_albedo[i], _layer.Normals[i], light, sunlight);
            _layer.Upload();
        }

        public void Draw(SpriteBatch batch, Vector2 center) => _layer.Draw(batch, center);
        public void Dispose() => _layer.Dispose();
    }
}
