#nullable enable

using System;
using Windows.UI;
using Windows.UI.Xaml.Data;
using Windows.UI.Xaml.Media;

namespace Screenbox.Converters
{
    /// <summary>
    /// 将uint (ARGB) 颜色转换为 SolidColorBrush
    /// </summary>
    internal sealed class UIntToColorBrushConverter : IValueConverter
    {
        public object Convert(object? value, Type targetType, object parameter, string language)
        {
            if (value is uint color)
            {
                return new SolidColorBrush(ColorHelper.FromArgb(
                    (byte)((color >> 24) & 0xFF),  // A
                    (byte)((color >> 16) & 0xFF),  // R
                    (byte)((color >> 8) & 0xFF),   // G
                    (byte)(color & 0xFF)           // B
                ));
            }
            // 默认绿色
            return new SolidColorBrush(ColorHelper.FromArgb(0xFF, 0x1D, 0xB9, 0x54));
        }

        public object ConvertBack(object value, Type targetType, object parameter, string language)
        {
            throw new NotImplementedException();
        }
    }
}
