#nullable enable

using System;
using CommunityToolkit.Mvvm.DependencyInjection;
using CommunityToolkit.Mvvm.Messaging;
using Screenbox.Core.Messages;
using Screenbox.Core.Services;
using Screenbox.Core.ViewModels;
using Windows.UI.Xaml;
using Windows.UI.Xaml.Controls;
using Windows.UI.Xaml.Controls.Primitives;
using Windows.UI.Xaml.Input;

namespace Screenbox.Controls;

/// <summary>
/// 桌面歌词控件
/// 支持独立于主窗口显示、位置记忆和拖拽功能
/// </summary>
public sealed partial class DesktopLyricsControl : UserControl, IRecipient<ToggleDesktopLyricsWindowMessage>, IRecipient<UpdateLyricsMessage>
{
    private Popup? _popup;
    private bool _isWindowVisible;
    private readonly ISettingsService _settingsService;
    private bool _isDragging;
    private double _dragStartX;
    private double _dragStartY;

    public static readonly DependencyProperty ViewModelProperty = DependencyProperty.Register(
        nameof(ViewModel),
        typeof(DesktopLyricsViewModel),
        typeof(DesktopLyricsControl),
        new PropertyMetadata(null));

    public DesktopLyricsViewModel? ViewModel
    {
        get => (DesktopLyricsViewModel?)GetValue(ViewModelProperty);
        set => SetValue(ViewModelProperty, value);
    }

    public DesktopLyricsControl()
    {
        this.InitializeComponent();

        _settingsService = Ioc.Default.GetRequiredService<ISettingsService>();
        ViewModel = Ioc.Default.GetRequiredService<DesktopLyricsViewModel>();
        DataContext = ViewModel;

        WeakReferenceMessenger.Default.RegisterAll(this);
    }

    public void Receive(UpdateLyricsMessage message)
    {
        if (ViewModel != null)
        {
            ViewModel.UpdateLyrics(message.HighlightedText, message.RemainingText);
        }
    }

    public void Receive(ToggleDesktopLyricsWindowMessage message)
    {
        if (message.IsVisible)
        {
            ShowPopup();
        }
        else
        {
            HidePopup();
        }
    }

    /// <summary>
    /// 显示桌面歌词窗口
    /// </summary>
    public void ShowPopup()
    {
        if (_isWindowVisible) return;

        // 读取保存的位置或使用默认值
        double offsetX = _settingsService.DesktopLyricsPosX > 0 ? _settingsService.DesktopLyricsPosX : 100;
        double offsetY = _settingsService.DesktopLyricsPosY > 0 ? _settingsService.DesktopLyricsPosY : 100;

        if (_popup == null)
        {
            _popup = new Popup
            {
                Child = this,
                IsLightDismissEnabled = false,
                IsOpen = true,
                HorizontalOffset = offsetX,
                VerticalOffset = offsetY
            };
        }
        else
        {
            _popup.HorizontalOffset = offsetX;
            _popup.VerticalOffset = offsetY;
            _popup.IsOpen = true;
        }

        _isWindowVisible = true;
        if (ViewModel != null)
        {
            ViewModel.IsWindowVisible = true;
        }
    }

    /// <summary>
    /// 隐藏桌面歌词窗口
    /// </summary>
    public void HidePopup()
    {
        if (_popup != null)
        {
            // 保存当前位置
            _settingsService.DesktopLyricsPosX = _popup.HorizontalOffset;
            _settingsService.DesktopLyricsPosY = _popup.VerticalOffset;
            _popup.IsOpen = false;
        }

        _isWindowVisible = false;
        if (ViewModel != null)
        {
            ViewModel.IsWindowVisible = false;
        }
    }

    /// <summary>
    /// 开始拖拽窗口
    /// </summary>
    private void OnPointerPressed(object sender, PointerRoutedEventArgs e)
    {
        if (e.Pointer.PointerDeviceType == Windows.Devices.Input.PointerDeviceType.Mouse)
        {
            var point = e.GetCurrentPoint(this);
            if (point.Properties.IsLeftButtonPressed)
            {
                _isDragging = true;
                _dragStartX = point.Position.X;
                _dragStartY = point.Position.Y;
                CapturePointer(e.Pointer);
                e.Handled = true;
            }
        }
    }

    /// <summary>
    /// 拖拽中
    /// </summary>
    private void OnPointerMoved(object sender, PointerRoutedEventArgs e)
    {
        if (!_isDragging || _popup == null) return;

        var point = e.GetCurrentPoint(this);
        var deltaX = point.Position.X - _dragStartX;
        var deltaY = point.Position.Y - _dragStartY;

        _popup.HorizontalOffset += deltaX;
        _popup.VerticalOffset += deltaY;

        _dragStartX = point.Position.X;
        _dragStartY = point.Position.Y;
    }

    /// <summary>
    /// 结束拖拽
    /// </summary>
    private void OnPointerReleased(object sender, PointerRoutedEventArgs e)
    {
        if (_isDragging)
        {
            _isDragging = false;
            ReleasePointerCapture(e.Pointer);
        }
    }

    /// <summary>
    /// 双击关闭歌词窗口
    /// </summary>
    private void OnDoubleTapped(object sender, DoubleTappedRoutedEventArgs e)
    {
        HidePopup();
        WeakReferenceMessenger.Default.Send(new ToggleDesktopLyricsWindowMessage(false));
    }

    public void Cleanup()
    {
        WeakReferenceMessenger.Default.UnregisterAll(this);
        if (_popup != null)
        {
            _popup.IsOpen = false;
            _popup = null;
        }
    }
}