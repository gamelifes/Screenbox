#nullable enable

using System;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using CommunityToolkit.Mvvm.Messaging;
using Screenbox.Core.Messages;
using Screenbox.Core.Services;

namespace Screenbox.Core.ViewModels;

public partial class DesktopLyricsViewModel : ObservableRecipient
{
    [ObservableProperty] private string? _highlightedText;
    [ObservableProperty] private string? _remainingText;
    [ObservableProperty] private uint _highlightColor;
    [ObservableProperty] private double _fontSize;
    [ObservableProperty] private bool _isWindowVisible;

    private readonly ISettingsService _settingsService;

    public DesktopLyricsViewModel(ISettingsService settingsService)
    {
        _settingsService = settingsService;
        _highlightColor = settingsService.LyricsHighlightColor;
        _fontSize = 48;
        IsActive = true;
    }

    public void Receive(SettingsChangedMessage message)
    {
        if (message.SettingsName == nameof(ISettingsService.LyricsHighlightColor))
        {
            HighlightColor = _settingsService.LyricsHighlightColor;
        }
    }

    public void UpdateLyrics(string? highlighted, string? remaining)
    {
        HighlightedText = highlighted;
        RemainingText = remaining;
    }

    [RelayCommand]
    private void ToggleVisibility()
    {
        IsWindowVisible = !IsWindowVisible;
        WeakReferenceMessenger.Default.Send(new ToggleDesktopLyricsWindowMessage(IsWindowVisible));
    }

    public void SetVisibility(bool visible)
    {
        IsWindowVisible = visible;
        WeakReferenceMessenger.Default.Send(new ToggleDesktopLyricsWindowMessage(visible));
    }
}
