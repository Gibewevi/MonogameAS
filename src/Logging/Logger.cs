using System;
using System.Diagnostics;
using System.Globalization;
using System.IO;
using System.Text;

namespace MonogameAS.Logging;

public static class Logger
{
    private static readonly object Gate = new();
    private static readonly string LogDirectory = Path.Combine(Environment.CurrentDirectory, "logs");
    private static readonly string LogPath = Path.Combine(LogDirectory, "monogameas.log");
    private static bool _initialized;

    public static void Initialize()
    {
        if (_initialized) return;
        Directory.CreateDirectory(LogDirectory);
        try
        {
            if (File.Exists(LogPath))
            {
                File.Delete(LogPath);
            }
        }
        catch { /* best effort */ }

        _initialized = true;
        Info("Logger initialized");
    }

    public static void Info(string message) => Write("INFO", message);
    public static void Warn(string message) => Write("WARN", message);
    public static void Error(string message, Exception? ex = null) =>
        Write("ERROR", ex is null ? message : $"{message} | {ex}");

    private static void Write(string level, string message)
    {
        if (!_initialized) Initialize();
        var timestamp = DateTime.UtcNow.ToString("yyyy-MM-dd HH:mm:ss.fff", CultureInfo.InvariantCulture);
        var line = $"{timestamp} [{level}] {message}";

        lock (Gate)
        {
            try
            {
                File.AppendAllText(LogPath, line + Environment.NewLine, Encoding.UTF8);
            }
            catch { /* ignore logging failures */ }
        }

        Debug.WriteLine(line);
        Console.WriteLine(line);
    }

    public static string LogFilePath => LogPath;
}
