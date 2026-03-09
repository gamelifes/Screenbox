#nullable enable

using System;
using Windows.UI.Xaml.Data;

namespace Screenbox.Converters;

/// <summary>
/// 卡拉OK高亮转换器 - 返回高亮部分的文本
/// </summary>
public class KaraokeHighlightConverter : IValueConverter
{
    public object Convert(object value, Type targetType, object parameter, string language)
    {
        string text = value as string ?? string.Empty;
        
        int highlightedCount = 0;
        if (parameter is int count)
        {
            highlightedCount = count;
        }
        else if (parameter is string strCount && int.TryParse(strCount, out int parsed))
        {
            highlightedCount = parsed;
        }

        highlightedCount = Math.Max(0, Math.Min(highlightedCount, text.Length));
        
        return text.Length > 0 && highlightedCount > 0 
            ? text.Substring(0, highlightedCount) 
            : string.Empty;
    }

    public object ConvertBack(object value, Type targetType, object parameter, string language)
    {
        throw new NotImplementedException();
    }
}

/// <summary>
/// 卡拉OK剩余文本转换器 - 返回未高亮部分的文本
/// </summary>
public class KaraokeRemainingConverter : IValueConverter
{
    public object Convert(object value, Type targetType, object parameter, string language)
    {
        string text = value as string ?? string.Empty;
        
        int highlightedCount = 0;
        if (parameter is int count)
        {
            highlightedCount = count;
        }
        else if (parameter is string strCount && int.TryParse(strCount, out int parsed))
        {
            highlightedCount = parsed;
        }

        highlightedCount = Math.Max(0, Math.Min(highlightedCount, text.Length));
        
        return highlightedCount < text.Length 
            ? text.Substring(highlightedCount) 
            : string.Empty;
    }

    public object ConvertBack(object value, Type targetType, object parameter, string language)
    {
        throw new NotImplementedException();
    }
}