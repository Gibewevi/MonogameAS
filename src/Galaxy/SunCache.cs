using System;
using System.Collections.Generic;
using Microsoft.Xna.Framework.Graphics;

namespace MonogameAS.Galaxy;

/// <summary>
/// Simple LRU cache per LOD for baked sun textures.
/// Each galaxy zoom level keeps its own crisp, pixel-stepped stellar textures.
/// </summary>
internal sealed class SunCache : IDisposable
{

    private readonly GraphicsDevice _device;
    private readonly int _capacityPerLod;
    private readonly Dictionary<int, Dictionary<BakeKey, CacheEntry>> _maps = new();
    private readonly Dictionary<int, LinkedList<BakeKey>> _orders = new();

    private sealed class CacheEntry
    {
        public required SunTextures Textures;
        public required LinkedListNode<BakeKey> Node;
    }

    public int Hits { get; private set; }
    public int Misses { get; private set; }

    public SunCache(GraphicsDevice device, int capacityPerLod = 2048)
    {
        _device = device;
        _capacityPerLod = capacityPerLod;
    }

    public SunTextures GetOrBake(int lod, int seed, int classId, int size, int steps, int cellSizePx)
    {
        var key = new BakeKey(seed, classId, size, steps, cellSizePx);
        var (map, order) = MapFor(lod);

        if (map.TryGetValue(key, out var entry))
        {
            order.Remove(entry.Node);
            order.AddLast(entry.Node);
            Hits++;
            return entry.Textures;
        }

        var baked = SunGenerator.Bake(_device, seed, classId, size, steps, cellSizePx);
        var node = new LinkedListNode<BakeKey>(key);
        order.AddLast(node);
        map[key] = new CacheEntry { Textures = baked, Node = node };
        Misses++;

        EvictIfNeeded(map, order);
        return baked;
    }

    private void EvictIfNeeded(Dictionary<BakeKey, CacheEntry> map, LinkedList<BakeKey> order)
    {
        while (order.Count > _capacityPerLod)
        {
            var oldest = order.First!;
            order.RemoveFirst();
            if (map.Remove(oldest.Value, out var entry))
            {
                DisposeEntry(entry);
            }
        }
    }

    private (Dictionary<BakeKey, CacheEntry> map, LinkedList<BakeKey> order) MapFor(int lod)
    {
        if (!_maps.TryGetValue(lod, out var map))
        {
            map = new Dictionary<BakeKey, CacheEntry>();
            _maps[lod] = map;
        }

        if (!_orders.TryGetValue(lod, out var order))
        {
            order = new LinkedList<BakeKey>();
            _orders[lod] = order;
        }

        return (map, order);
    }

    private readonly record struct BakeKey(int Seed, int ClassId, int Size, int Steps, int CellSize);

    private static void DisposeEntry(CacheEntry entry)
    {
        entry.Textures.Albedo.Dispose();
        entry.Textures.Halo.Dispose();
    }

    public void Dispose()
    {
        foreach (var map in _maps.Values)
        {
            foreach (var entry in map.Values)
                DisposeEntry(entry);
        }
        _maps.Clear();
        _orders.Clear();
    }
}
