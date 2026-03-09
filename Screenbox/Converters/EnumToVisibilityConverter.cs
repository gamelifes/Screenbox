#nullable enable

using System;
using Windows.UI.Xaml;
using Windows.UI.Xaml.Data;

namespace Screenbox.Converters;

/// <summary>
/// 枚举值比较转换器 - 将枚举值与指定值比较返回 Visibility
/// </summary>
public class EnumToVisibilityConverter : IValueConverter
{
    public object Convert(object value, Type targetType, object parameter, string language)
    {
        if (value == null || parameter == null)
            return Visibility.Collapsed;

        try
        {
            var valueEnum = Enum.Parse(value.GetType(), value.ToString() ?? string.Empty);
            var paramEnum = Enum.Parse(value.GetType(), parameter.ToString() ?? string.Empty);
            return valueEnum.Equals(paramEnum) ? Visibility.Visible : Visibility.Collapsed;
        }
        catch
        {
            return Visibility.Collapsed;
        }
    }

    public object ConvertBack(object value, Type targetType, object parameter, string language)
    {
        throw new NotImplementedException();
    }
}

/// <summary>
/// 枚举值比较转换器（反转）- 将枚举值与指定值比较返回 Visibility（反转）
/// </summary>
public class NotEnumToVisibilityConverter : IValueConverter
{
    public object Convert(object value, Type targetType, object parameter, string language)
    {
        if (value == null || parameter == null)
            return Visibility.Visible;

        try
        {
            var valueEnum = Enum.Parse(value.GetType(), value.ToString() ?? string.Empty);
            var paramEnum = Enum.Parse(value.GetType(), parameter.ToString() ?? string.Empty);
            return valueEnum.Equals(paramEnum) ? Visibility.Collapsed : Visibility.Visible;
        }
        catch
        {
            return Visibility.Visible;
        }
    }

    public object ConvertBack(object value, Type targetType, object parameter, string language)
    {
        throw new NotImplementedException();
    }
}