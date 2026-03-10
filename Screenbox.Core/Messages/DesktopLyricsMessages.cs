#nullable enable

using System.Threading;
using LibVLCSharp.Shared;

namespace Screenbox.Core.Messages;

/// <summary>
/// Message to toggle lyrics visibility in the player.
/// </summary>
public class ToggleLyricsMessage
{
}

/// <summary>
/// Utility class to ensure LibVLC core is initialized before use.
/// Uses background initialization with proper synchronization.
/// </summary>
public static class LibVlcInitializer
{
    private static readonly SemaphoreSlim InitSemaphore = new(1, 1);
    private static bool _isInitialized;

    /// <summary>
    /// Ensures LibVLC core is initialized. Thread-safe and idempotent.
    /// If initialization is in progress, waits for it to complete.
    /// </summary>
    public static void EnsureInitialized()
    {
        if (_isInitialized) return;

        InitSemaphore.Wait();
        try
        {
            if (_isInitialized) return;
            LibVLCSharp.Shared.Core.Initialize();
            _isInitialized = true;
        }
        finally
        {
            InitSemaphore.Release();
        }
    }
}
