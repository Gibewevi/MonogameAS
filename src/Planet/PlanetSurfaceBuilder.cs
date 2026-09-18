using System;
using System.Collections.Generic;
using Microsoft.Xna.Framework;

namespace MonogameAS.Planet;

/// <summary>
/// Generation-only scratch space. Each pass consumes fields from earlier passes;
/// only immutable surface cells and colors survive in the atlas.
/// </summary>
internal sealed class PlanetSurfaceBuilder
{
    private readonly PlanetKey _key;
    private readonly PlanetEnvironment _e;
    private readonly int _width;
    private readonly int _height;
    private readonly Vector3[] _points;
    private readonly float[] _elevation;
    private readonly float[] _heat;
    private readonly float[] _crater;
    private readonly float[] _material;
    private readonly float[] _temperature;
    private readonly float[] _moisture;
    private readonly float[] _river;
    private readonly float[] _lakeDepth;
    private readonly float[] _rowArea;
    private readonly float _meanTemperature;
    private readonly float _liquidPotential;
    private float _sea;
    private float _coverage;

    public PlanetSurfaceBuilder(PlanetKey key, PlanetEnvironment environment, int width, int height)
    {
        _key = key;
        _e = environment;
        _width = width;
        _height = height;
        _meanTemperature = environment.MeanTemperatureC;
        _liquidPotential = environment.LiquidWaterPotential;
        var count = width * height;
        _points = new Vector3[count];
        _elevation = new float[count];
        _heat = new float[count];
        _crater = new float[count];
        _material = new float[count];
        _temperature = new float[count];
        _moisture = new float[count];
        _river = new float[count];
        _lakeDepth = new float[count];
        _rowArea = new float[height];
    }

    public void Build(PlanetSurfaceCell[] cells, Color[] colors, PlanetPalette palette)
    {
        BuildGeology();
        FindSeaLevel();
        BuildClimate();
        BuildDrainage();
        for (var i = 0; i < cells.Length; i++)
        {
            var terrain = Classify(i);
            cells[i] = new PlanetSurfaceCell(terrain, _elevation[i], _temperature[i],
                _moisture[i], _heat[i], _river[i], _crater[i]);
            colors[i] = LocalColor(i, terrain, palette);
        }
    }

    private void BuildGeology()
    {
        var p = _key.Params;
        var scale = _e.ContinentalScale * Math.Clamp(PlanetWorldMap.Finite(p.ElevScale, 0.09f) / 0.09f, 0.15f, 2.5f);
        var formation = Clamp((0.5f - _e.AgeGyr) / 0.5f);
        var erosion = _e.Erosion * (0.35f + _e.AgeGyr / 18) * (0.25f + _e.Atmosphere * 0.3f + _e.Water * 0.45f);
        var impacts = MakeFeatures((int)MathF.Round(_e.Impacts * (14 + 46 * MathF.Sqrt(_e.AgeGyr / 12) + formation * 20)), 0x349AC, 0.045f, 0.23f);
        var vents = MakeFeatures(_e.Volcanism > 0.01f ? 3 + (int)(_e.Volcanism * 17) : 0, 0x784BC, 0.07f, 0.22f);
        for (var y = 0; y < _height; y++)
        {
            var latitude = ((y + 0.5f) / _height - 0.5f) * MathHelper.Pi;
            var cosLatitude = MathF.Cos(latitude);
            _rowArea[y] = cosLatitude;
            for (var x = 0; x < _width; x++)
            {
                var i = y * _width + x;
                var longitude = ((x + 0.5f) / _width - 0.5f) * MathHelper.TwoPi;
                var point = new Vector3(MathF.Sin(longitude) * cosLatitude, MathF.Sin(latitude), MathF.Cos(longitude) * cosLatitude);
                _points[i] = point;
                // Coherent domain warping breaks round noise blobs into coastlines.
                var warp = new Vector3(Noise(point, 1.7f, 0x12F, 2), Noise(point, 1.7f, 0x27A, 2), Noise(point, 1.7f, 0x39B, 2));
                var warped = point + (warp - new Vector3(0.5f)) * 0.65f;
                var continents = SphereNoise.FractalBounded(warped * scale, _key.Seed, p.ElevOctaves, p.ElevLacunarity, p.ElevPersistence);
                var detail = Noise(warped, scale * 3.2f, 0x458, 3);
                var fold = Noise(warped, scale * 1.8f, 0x571, 3);
                var ridge = MathF.Pow(1 - MathF.Abs(fold * 2 - 1), 7);
                var uplift = ridge * _e.Tectonics * _e.Relief * (0.75f + _e.Silicates * 0.5f) * (1 - erosion * 0.6f);
                var elevation = 0.43f + (continents - 0.5f) * 1.7f
                    + uplift * 0.28f + (detail - 0.5f) * _e.Relief * (0.38f - erosion * 0.22f);
                var fault = MathF.Pow(1 - MathF.Abs(Noise(warped, scale * 2.7f, 0x628, 2) * 2 - 1), 18);
                var heat = _e.Volcanism * (0.8f + _e.Iron * 0.5f) * (0.03f + fault * _e.Tectonics * 0.45f)
                    + formation * (0.34f + detail * 0.6f);
                foreach (var vent in vents)
                {
                    var distance2 = Vector3.DistanceSquared(point, vent.Center) / (vent.Radius * vent.Radius);
                    if (distance2 >= 1) continue;
                    var cone = 1 - MathF.Sqrt(distance2);
                    elevation += cone * _e.Volcanism * 0.12f;
                    heat = Math.Max(heat, Smooth(0, 0.85f, cone) * _e.Volcanism * (1.4f + vent.Strength * 0.45f) + formation * 0.35f);
                }
                _heat[i] = Clamp(heat);
                var crater = 0f;
                foreach (var impact in impacts)
                {
                    var distance2 = Vector3.DistanceSquared(point, impact.Center) / (impact.Radius * impact.Radius);
                    if (distance2 >= 1.44f) continue;
                    var d = MathF.Sqrt(distance2);
                    var preservation = (1 - erosion * 0.8f) * (1 - _heat[i] * 0.85f) * impact.Strength;
                    var floor = -Smooth(0.88f, 0.48f, d) * preservation;
                    var rim = Math.Max(0, 1 - MathF.Abs(d - 0.92f) / 0.19f) * preservation;
                    var shape = floor + rim;
                    elevation += (floor * 0.095f + rim * 0.065f) * (0.5f + impact.Radius * 3);
                    if (MathF.Abs(shape) > MathF.Abs(crater)) crater = shape;
                }
                _crater[i] = crater;
                _elevation[i] = Math.Clamp(elevation, 0.015f, 0.985f);
                _material[i] = Noise(point, 3.4f, 0x79A, 2);
            }
        }
    }

    private void FindSeaLevel()
    {
        // Area-weighted quantile: polar UV cells must not count as equatorial ones.
        // Water is an inventory, not a planet type; frozen basins retain it too.
        var evaporation = 1 - Smooth(65, 155, _meanTemperature);
        var retention = _e.Atmosphere < 0.035f ? 1 - Smooth(-35, 5, _meanTemperature) : 1;
        var seaBias = Math.Clamp(PlanetWorldMap.Finite(_key.Params.ElevSeaLevel, 0.42f) - 0.42f, -0.42f, 0.58f);
        _coverage = Clamp(_e.Water * evaporation * retention + seaBias);
        if (_coverage <= 0.001f) { _sea = -1; return; }
        if (_coverage >= 0.999f) { _sea = 1; return; }
        var histogram = new float[1024];
        var area = 0f;
        for (var i = 0; i < _elevation.Length; i++)
        {
            var weight = _rowArea[i / _width];
            histogram[Math.Clamp((int)(_elevation[i] * 1023), 0, 1023)] += weight;
            area += weight;
        }
        var target = area * _coverage;
        var sum = 0f;
        for (var bin = 0; bin < histogram.Length; bin++)
        {
            sum += histogram[bin];
            if (sum < target) continue;
            _sea = (bin + 0.5f) / 1023;
            return;
        }
    }

    private void BuildClimate()
    {
        var waterDistance = DistanceFromWater();
        var tilt = MathF.Sin(_e.AxialTilt * MathHelper.Pi / 180);
        var gradient = (92 - _e.Atmosphere * 43) * (1 - tilt * tilt * 0.55f);
        for (var i = 0; i < _elevation.Length; i++)
        {
            var point = _points[i];
            var latitude = MathF.Abs(point.Y);
            var sea = _elevation[i] < _sea;
            var aboveSea = Math.Max(0, _elevation[i] - Math.Max(0.28f, _sea));
            var continentality = Clamp(waterDistance[i] / 25f);
            var circulation = Noise(point, 2.8f, 0x819, 3);
            var regional = (circulation - 0.5f) * 15;
            var latitudeHeat = (1f / 3 - latitude * latitude) * gradient;
            var temperature = _meanTemperature + latitudeHeat * (sea ? 0.80f : 1)
                + regional * (0.4f + continentality * 0.6f) - aboveSea * (35 + _e.Relief * 32)
                + Math.Max(0, _heat[i] - 0.12f) * (sea ? 108 : 80);
            _temperature[i] = temperature;

            // Subtropical descending air dries land; oceans and windward slopes
            // feed rainfall, while mountain chains cast broad rain shadows.
            var subtropicalDry = MathF.Exp(-MathF.Pow((latitude - 0.48f) / 0.19f, 2)) * 0.26f;
            var x = i % _width;
            var y = i / _width;
            var windward = Neighbor(x - 4, y);
            var rainShadow = Math.Max(0, _elevation[windward] - _elevation[i]) * 1.8f;
            var moisture = (_e.Water * 0.36f + (1 - continentality) * 0.44f + circulation * 0.55f
                - 0.16f - subtropicalDry - rainShadow - Math.Max(0, temperature - 30) * 0.006f)
                * Smooth(0.015f, 0.3f, _e.Atmosphere);
            _moisture[i] = Clamp(sea ? Math.Max(moisture, _e.Atmosphere * 0.85f) : moisture);
        }
    }

    private int[] DistanceFromWater()
    {
        var distances = new int[_elevation.Length];
        Array.Fill(distances, _width);
        var queue = new Queue<int>();
        for (var i = 0; i < distances.Length; i++)
            if (_elevation[i] < _sea)
            {
                distances[i] = 0;
                queue.Enqueue(i);
            }
        while (queue.TryDequeue(out var i))
        {
            var x = i % _width;
            var y = i / _width;
            for (var direction = 0; direction < 4; direction++)
            {
                var n = Neighbor(x + (direction == 0 ? -1 : direction == 1 ? 1 : 0), y + (direction == 2 ? -1 : direction == 3 ? 1 : 0));
                if (distances[n] <= distances[i] + 1) continue;
                distances[n] = distances[i] + 1;
                queue.Enqueue(n);
            }
        }
        return distances;
    }

    private void BuildDrainage()
    {
        if (_liquidPotential < 0.02f || _e.Water < 0.015f) return;
        var count = _elevation.Length;
        var visited = new bool[count];
        var filled = new float[count];
        var receiver = new int[count];
        Array.Fill(receiver, -1);
        var order = new int[count];
        var length = 0;
        var queue = new PriorityQueue<int, (float Height, int Index)>();
        var lowest = 0;
        for (var i = 0; i < count; i++)
        {
            if (_elevation[i] < _elevation[lowest]) lowest = i;
            if (_elevation[i] >= _sea) continue;
            visited[i] = true;
            filled[i] = _sea;
            queue.Enqueue(i, (_sea, i));
        }
        if (queue.Count == 0)
        {
            visited[lowest] = true;
            filled[lowest] = _elevation[lowest];
            queue.Enqueue(lowest, (filled[lowest], lowest));
        }
        // Priority flood finds a downhill spill path for every inland basin.
        // Accumulation follows that acyclic path; rivers cannot wander uphill.
        while (queue.TryDequeue(out var i, out _))
        {
            order[length++] = i;
            var x = i % _width;
            var y = i / _width;
            for (var dy = -1; dy <= 1; dy++)
            for (var dx = -1; dx <= 1; dx++)
            {
                if (dx == 0 && dy == 0) continue;
                var n = Neighbor(x + dx, y + dy);
                if (visited[n]) continue;
                visited[n] = true;
                filled[n] = Math.Max(_elevation[n], filled[i] + 0.000001f);
                receiver[n] = i;
                queue.Enqueue(n, (filled[n], n));
            }
        }
        var flow = new float[count];
        for (var step = length - 1; step >= 0; step--)
        {
            var i = order[step];
            var rainfall = Math.Max(0, _moisture[i] - 0.19f) * _liquidPotential
                * Smooth(FreezingPoint - 8, FreezingPoint + 6, _temperature[i]);
            flow[i] += rainfall * _rowArea[i / _width];
            if (receiver[i] >= 0) flow[receiver[i]] += flow[i];
        }
        for (var i = 0; i < count; i++)
        {
            if (_elevation[i] < _sea) continue;
            var discharge = Clamp((flow[i] - 4.5f) / 28);
            if (!LiquidAt(i)) discharge = 0;
            _river[i] = discharge;
            if (discharge > 0)
            {
                _moisture[i] = Math.Max(_moisture[i], 0.5f + discharge * 0.3f);
                // Erosion carves the bed; the resolved spill surface still drives flow.
                _elevation[i] = Math.Max(_sea + 0.001f, _elevation[i] - discharge * _e.Erosion * 0.018f);
            }
            if (flow[i] > 1.3f && _moisture[i] > 0.34f)
                _lakeDepth[i] = Math.Max(0, filled[i] - _elevation[i]);
        }
    }

    private PlanetTerrain Classify(int i)
    {
        var h = _elevation[i];
        var temperature = _temperature[i];
        var wetBasin = h < _sea || _lakeDepth[i] > 0.012f;
        var waterAvailable = _e.Water > 0.005f || _coverage > 0.005f;
        if (wetBasin && waterAvailable)
        {
            if (temperature < FreezingPoint)
                return temperature < FreezingPoint - 22 ? PlanetTerrain.Glacier : PlanetTerrain.Ice;
            if (LiquidAt(i))
                return _sea - h > Safe(_key.Params.ElevShelfBand, 0.10f, 0.01f, 0.3f)
                    ? PlanetTerrain.DeepWater : PlanetTerrain.ShelfWater;
        }
        // Water quenches exposed magma. A submarine vent warms the liquid above
        // it; only dry vents become lava, including vents amid otherwise icy land.
        if (_heat[i] > 0.84f) return PlanetTerrain.LavaHot;
        if (_heat[i] > 0.64f) return PlanetTerrain.Lava;
        if (_river[i] > 0.09f && LiquidAt(i)) return PlanetTerrain.River;
        var snowfall = _e.Atmosphere > 0.08f && _moisture[i] * _e.Water > 0.065f;
        var trappedFrost = _e.Water > 0.08f && _crater[i] < -0.35f && temperature < -45;
        if (temperature < FreezingPoint + 1 && waterAvailable && (snowfall || trappedFrost))
            return temperature < -32 && _moisture[i] > 0.4f ? PlanetTerrain.Glacier : PlanetTerrain.Snow;
        if (_heat[i] > 0.32f) return PlanetTerrain.Basalt;

        var beach = Safe(_key.Params.ElevBeachBand, 0.02f, 0, 0.08f);
        if (_coverage > 0.01f && h >= _sea && h < _sea + beach && LiquidAt(i)) return PlanetTerrain.Beach;
        if (_crater[i] > 0.36f) return PlanetTerrain.CraterRim;
        if (_crater[i] < -0.40f && _moisture[i] < 0.5f) return PlanetTerrain.CraterFloor;
        if ((wetBasin || h < 0.28f) && _moisture[i] < 0.26f && _e.Salinity > 0.45f && _e.Water > 0.05f)
            return PlanetTerrain.SaltFlat;
        var mountain = Safe(_key.Params.ElevMtnLevel, 0.70f, 0.4f, 0.98f);
        var hill = Safe(_key.Params.ElevHillLevel, 0.53f, 0.25f, mountain);
        if (h > mountain - _e.Relief * _e.Tectonics * 0.06f) return PlanetTerrain.Mountains;
        if (_moisture[i] < 0.25f && temperature > -12) return PlanetTerrain.Desert;
        var viable = LocalLifePotential(i);
        if (viable > 0.16f && _moisture[i] > 0.50f) return PlanetTerrain.Forest;
        if (h > hill) return PlanetTerrain.Hills;
        if (viable < 0.13f || _moisture[i] < 0.34f) return PlanetTerrain.DryPlain;
        return PlanetTerrain.Plains;
    }

    private Color LocalColor(int i, PlanetTerrain terrain, PlanetPalette palette)
    {
        var color = PlanetWorldMap.ColorFor(terrain, palette);
        if (terrain == PlanetTerrain.Hills)
            color = Color.Lerp(Color.Lerp(palette.DryPlain, palette.Mountains, 0.52f), palette.Hills,
                Smooth(0.10f, 0.35f, LocalLifePotential(i)) * Smooth(0.18f, 0.5f, _moisture[i]));
        var material = _material[i];
        // Three regional steps, not per-pixel RGB jitter: neighboring biomes keep
        // a common mineral tint and large readable clusters at thumbnail scale.
        var step = material < 0.40f ? 0 : material > 0.59f ? 2 : 1;
        if (terrain is PlanetTerrain.DeepWater or PlanetTerrain.ShelfWater or PlanetTerrain.River)
            return Color.Lerp(color, _temperature[i] < 4 ? palette.Ice : palette.ShelfWater, step * 0.045f);
        if (terrain is PlanetTerrain.Lava or PlanetTerrain.LavaHot)
            return Color.Lerp(color, palette.LavaHot, step * 0.09f);
        if (terrain is PlanetTerrain.Ice or PlanetTerrain.Glacier or PlanetTerrain.Snow)
            return Color.Lerp(color, palette.Ice, step * 0.08f);
        color = Color.Lerp(color, material < 0.5f ? palette.DryPlain : palette.Beach, step * 0.055f);
        if (terrain is PlanetTerrain.Hills or PlanetTerrain.Mountains or PlanetTerrain.CraterRim or PlanetTerrain.CraterFloor)
        {
            var x = i % _width;
            var y = i / _width;
            var slope = _elevation[Neighbor(x - 1, y + 1)] - _elevation[Neighbor(x + 1, y - 1)];
            if (slope > 0.014f) color = Color.Lerp(color, palette.Beach, 0.16f);
            if (slope < -0.014f) color = Color.Lerp(color, palette.Basalt, 0.18f);
        }
        return color;
    }

    private float FreezingPoint => -2 - _e.Salinity * 13;
    private float LocalLifePotential(int i) => _e.LifePotential
        * Smooth(-12, 10, _temperature[i]) * (1 - Smooth(34, 65, _temperature[i]))
        * Smooth(0.04f, 0.25f, _e.Atmosphere);
    private bool LiquidAt(int i) => _e.Atmosphere >= 0.035f && _liquidPotential > 0.015f
        && _temperature[i] >= FreezingPoint && _temperature[i] < 65 + _e.Atmosphere * 65;

    private int Neighbor(int x, int y)
    {
        if (y < 0) { y = -y - 1; x += _width / 2; }
        if (y >= _height) { y = 2 * _height - y - 1; x += _width / 2; }
        x = (x % _width + _width) % _width;
        return y * _width + x;
    }

    private Feature[] MakeFeatures(int count, int channel, float minRadius, float maxRadius)
    {
        var features = new Feature[count];
        for (var i = 0; i < count; i++)
        {
            var longitude = SphereNoise.Hash(i, channel, 1, _key.Seed) * MathHelper.TwoPi;
            var vertical = SphereNoise.Hash(i, channel, 2, _key.Seed) * 2 - 1;
            var radial = MathF.Sqrt(1 - vertical * vertical);
            var center = new Vector3(MathF.Sin(longitude) * radial, vertical, MathF.Cos(longitude) * radial);
            var size = SphereNoise.Hash(i, channel, 3, _key.Seed);
            features[i] = new Feature(center, MathHelper.Lerp(minRadius, maxRadius, size * size),
                0.55f + SphereNoise.Hash(i, channel, 4, _key.Seed) * 0.45f);
        }
        return features;
    }

    private float Noise(Vector3 point, float scale, int channel, int octaves) =>
        SphereNoise.Fractal(point * scale, _key.Seed ^ channel, octaves, 2.17f, 0.47f);
    private static float Clamp(float value) => Math.Clamp(value, 0, 1);
    private static float Safe(float value, float fallback, float min, float max) => Math.Clamp(PlanetWorldMap.Finite(value, fallback), min, max);
    private static float Smooth(float a, float b, float value)
    {
        var t = Clamp((value - a) / (b - a));
        return t * t * (3 - 2 * t);
    }
    private readonly record struct Feature(Vector3 Center, float Radius, float Strength);
}
