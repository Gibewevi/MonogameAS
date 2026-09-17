using System;
using System.Collections.Generic;
using Microsoft.Xna.Framework.Graphics;
using MonogameAS.State;

namespace MonogameAS.Galaxy;

/// <summary>Bounded, reusable animated stars for the two close galaxy zoom levels.</summary>
internal sealed class GalaxySunCache : IDisposable
{
    private readonly GraphicsDevice _device;
    private readonly int _capacity;
    private readonly Dictionary<CacheKey, Entry> _entries = new();
    private readonly LinkedList<CacheKey> _recent = new();

    public GalaxySunCache(GraphicsDevice device, int capacity = 512)
    {
        _device = device;
        _capacity = Math.Max(1, capacity);
    }

    public int Count => _entries.Count;

    public PixelSunRenderer GetOrCreate(SunKey key, int diameter)
    {
        var cacheKey = new CacheKey(key, diameter);
        if (_entries.TryGetValue(cacheKey, out var entry))
        {
            _recent.Remove(entry.Node);
            _recent.AddLast(entry.Node);
            return entry.Renderer;
        }

        var renderer = new PixelSunRenderer(_device, key, diameter, SunRenderSettings.GalaxyCellSize);
        _entries.Add(cacheKey, new Entry(renderer, _recent.AddLast(cacheKey)));
        if (_entries.Count > _capacity)
        {
            var oldest = _recent.First!;
            _recent.RemoveFirst();
            _entries.Remove(oldest.Value, out var evicted);
            evicted!.Renderer.Dispose();
        }
        return renderer;
    }

    public void Dispose()
    {
        foreach (var entry in _entries.Values) entry.Renderer.Dispose();
        _entries.Clear();
        _recent.Clear();
    }

    private readonly record struct CacheKey(SunKey Star, int Diameter);
    private sealed record Entry(PixelSunRenderer Renderer, LinkedListNode<CacheKey> Node);
}
