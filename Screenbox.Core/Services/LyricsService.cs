#nullable enable

using System;
using System.Collections.Generic;
using System.IO;
using System.Text.RegularExpressions;
using TagLib;
using System.Threading.Tasks;
using Screenbox.Core.Helpers;
using Windows.Storage;


namespace Screenbox.Core.Services;

public class LyricLine
{
    public TimeSpan Time { get; set; }
    public string Text { get; set; } = string.Empty;
}

/// <summary>
/// 支持逐字高亮的歌词行
/// </summary>
public class EnhancedLyricLine
{
    public TimeSpan StartTime { get; set; }
    public TimeSpan EndTime { get; set; }
    public string Text { get; set; } = string.Empty;
    
    /// <summary>
    /// 逐字时间戳列表
    /// </summary>
    public List<LyricChar> Chars { get; set; } = new();
}

public class LyricChar
{
    public TimeSpan StartTime { get; set; }
    public TimeSpan EndTime { get; set; }
    public char Character { get; set; }
}

public class Lyrics
{
    public string? Title { get; set; }
    public string? Artist { get; set; }
    public string? Album { get; set; }
    public List<LyricLine> Lines { get; set; } = new();
    
    /// <summary>
    /// 逐字解析的歌词行（用于卡拉OK效果）
    /// </summary>
    public List<EnhancedLyricLine> EnhancedLines { get; set; } = new();
}

public interface ILyricsService
{
    Lyrics? ParseLrc(string content);
    Lyrics? LoadLyricsFile(string filePath);
    Lyrics? LoadEmbeddedLyrics(string filePath);
    Task<Lyrics?> LoadEmbeddedLyricsAsync(StorageFile file);
}

public class LyricsService : ILyricsService
{
    private static readonly Regex LrcLineRegex = new(@"\[(\d{2}):(\d{2})\.(\d{2,3})\](.*)", RegexOptions.Compiled);
    private static readonly Regex MetaRegex = new(@"\[(ti|ar|al|au|length|by|offset):(.+)\]", RegexOptions.Compiled);
    // 逐字时间戳正则: [mm:ss.xx]<mm:ss.xx>字<mm:ss.xx>字
    private static readonly Regex EnhancedLineRegex = new(@"\[(\d{2}):(\d{2})\.(\d{2,3})\](<(\d{2}):(\d{2})\.(\d{2,3})>([^<]+))", RegexOptions.Compiled);

    public Lyrics? ParseLrc(string content)
    {
        System.Diagnostics.Debug.WriteLine($"[LyricsService] ParseLrc called with content length: {content?.Length ?? 0}");
        
        if (string.IsNullOrWhiteSpace(content))
        {
            System.Diagnostics.Debug.WriteLine("[LyricsService] ParseLrc: content is null or empty, returning null");
            return null;
        }

        var lyrics = new Lyrics();
        var lines = content.Split(new[] { "\r\n", "\r", "\n" }, StringSplitOptions.None);
        System.Diagnostics.Debug.WriteLine($"[LyricsService] ParseLrc: processing {lines.Length} lines");

        foreach (var line in lines)
        {
            var trimmedLine = line.Trim();
            if (string.IsNullOrEmpty(trimmedLine))
                continue;

            // Check for metadata
            var metaMatch = MetaRegex.Match(trimmedLine);
            if (metaMatch.Success)
            {
                var key = metaMatch.Groups[1].Value.ToLower();
                var value = metaMatch.Groups[2].Value.Trim();
                switch (key)
                {
                    case "ti":
                        lyrics.Title = value;
                        break;
                    case "ar":
                        lyrics.Artist = value;
                        break;
                    case "al":
                        lyrics.Album = value;
                        break;
                }
                continue;
            }

            // Check for time-tagged lyrics
            var lrcMatches = LrcLineRegex.Matches(trimmedLine);
            if (lrcMatches.Count > 0)
            {
                // Get text from the last match (some LRC files have multiple timestamps per line)
                var text = lrcMatches[lrcMatches.Count - 1].Groups[4].Value.Trim();
                
                foreach (Match match in lrcMatches)
                {
                    if (!int.TryParse(match.Groups[1].Value, out int minutes) ||
                        !int.TryParse(match.Groups[2].Value, out int seconds))
                    {
                        continue;
                    }

                    var millisecondsStr = match.Groups[3].Value;
                    if (!int.TryParse(millisecondsStr.PadRight(3, '0'), out int milliseconds))
                    {
                        continue;
                    }

                    if (millisecondsStr.Length == 2)
                        milliseconds *= 10;

                    var time = new TimeSpan(0, 0, minutes, seconds, milliseconds);
                    lyrics.Lines.Add(new LyricLine { Time = time, Text = text });
                    
                    // 解析逐字时间戳
                    ParseEnhancedLine(lyrics, time, text, trimmedLine);
                }
            }
        }

        System.Diagnostics.Debug.WriteLine($"[LyricsService] ParseLrc: parsed {lyrics.Lines.Count} lyric lines, {lyrics.EnhancedLines.Count} enhanced lines");
        return lyrics.Lines.Count > 0 ? lyrics : null;
    }
    
    /// <summary>
    /// 解析逐字时间戳歌词
    /// 支持格式: [00:12.34]<00:12.50>这<00:12.70>是<00:12.90>一<00:13.10>句
    /// </summary>
    private void ParseEnhancedLine(Lyrics lyrics, TimeSpan lineStartTime, string text, string rawLine)
    {
        try
        {
            // 查找逐字时间戳模式
            var enhancedMatch = System.Text.RegularExpressions.Regex.Match(rawLine, 
                @"\[(\d{2}):(\d{2})\.(\d{2,3})\](.+)$", 
                RegexOptions.Compiled);
            
            if (!enhancedMatch.Success)
                return;
                
            string contentPart = enhancedMatch.Groups[4].Value;
            
            // 检查是否包含逐字时间戳 <mm:ss.xx>
            if (!contentPart.Contains("<"))
                return;
                
            var enhancedLine = new EnhancedLyricLine
            {
                StartTime = lineStartTime,
                Text = text
            };
            
            // 解析逐字时间戳: <mm:ss.xx>字
            var charMatches = System.Text.RegularExpressions.Regex.Matches(contentPart, 
                @"<(\d{2}):(\d{2})\.(\d{2,3})>([^<]+)", 
                RegexOptions.Compiled);
            
            if (charMatches.Count == 0)
                return;
                
            TimeSpan prevTime = lineStartTime;
            
            foreach (System.Text.RegularExpressions.Match charMatch in charMatches)
            {
                if (!int.TryParse(charMatch.Groups[1].Value, out int minutes) ||
                    !int.TryParse(charMatch.Groups[2].Value, out int seconds))
                    continue;
                    
                var msStr = charMatch.Groups[3].Value;
                if (!int.TryParse(msStr.PadRight(3, '0'), out int milliseconds))
                    continue;
                    
                if (msStr.Length == 2)
                    milliseconds *= 10;
                    
                var charTime = new TimeSpan(0, 0, minutes, seconds, milliseconds);
                string charText = charMatch.Groups[4].Value;
                
                // 添加每个字符
                foreach (char c in charText)
                {
                    enhancedLine.Chars.Add(new LyricChar
                    {
                        StartTime = prevTime,
                        EndTime = charTime,
                        Character = c
                    });
                    prevTime = charTime;
                }
            }
            
            // 设置结束时间
            if (enhancedLine.Chars.Count > 0)
            {
                // 估算结束时间为最后一个字符后约100ms
                var lastChar = enhancedLine.Chars[enhancedLine.Chars.Count - 1];
                lastChar.EndTime = lastChar.EndTime + TimeSpan.FromMilliseconds(100);
                enhancedLine.EndTime = lastChar.EndTime;
                lyrics.EnhancedLines.Add(enhancedLine);
            }
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"[LyricsService] ParseEnhancedLine error: {ex.Message}");
        }
    }

    public Lyrics? LoadLyricsFile(string filePath)
    {
        try
        {
            System.Diagnostics.Debug.WriteLine($"[LyricsService] LoadLyricsFile: attempting to load from {filePath}");
            
            if (string.IsNullOrEmpty(filePath) || !System.IO.File.Exists(filePath))
            {
                System.Diagnostics.Debug.WriteLine("[LyricsService] LoadLyricsFile: file does not exist");
                return null;
            }

            var content = System.IO.File.ReadAllText(filePath);
            System.Diagnostics.Debug.WriteLine($"[LyricsService] LoadLyricsFile: read {content.Length} characters");
            
            var result = ParseLrc(content);
            System.Diagnostics.Debug.WriteLine($"[LyricsService] LoadLyricsFile: result = {(result != null ? $"{result.Lines.Count} lines" : "null")}");
            return result;
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"[LyricsService] LoadLyricsFile exception: {ex.Message}");
            return null;
        }
    }

    public Lyrics? LoadEmbeddedLyrics(string filePath)
    {
        try
        {
            System.Diagnostics.Debug.WriteLine($"[LyricsService] LoadEmbeddedLyrics: attempting to load from {filePath}");
            
            if (string.IsNullOrEmpty(filePath) || !System.IO.File.Exists(filePath))
            {
                System.Diagnostics.Debug.WriteLine("[LyricsService] LoadEmbeddedLyrics: file does not exist");
                return null;
            }

            using var file = TagLib.File.Create(filePath);
            string? lyricsContent = null;

            if (file.Tag.Lyrics != null && !string.IsNullOrWhiteSpace(file.Tag.Lyrics))
            {
                lyricsContent = file.Tag.Lyrics;
                System.Diagnostics.Debug.WriteLine("[LyricsService] LoadEmbeddedLyrics: found lyrics in tag");
            }
            else if (file.Tag.Comment != null && !string.IsNullOrWhiteSpace(file.Tag.Comment))
            {
                lyricsContent = file.Tag.Comment;
                System.Diagnostics.Debug.WriteLine("[LyricsService] LoadEmbeddedLyrics: found lyrics in comment tag");
            }

            if (string.IsNullOrWhiteSpace(lyricsContent))
            {
                System.Diagnostics.Debug.WriteLine("[LyricsService] LoadEmbeddedLyrics: no embedded lyrics found");
                return null;
            }

            return ParseLrc(lyricsContent);
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"[LyricsService] LoadEmbeddedLyrics exception: {ex.Message}");
            return null;
        }
    }

    public async Task<Lyrics?> LoadEmbeddedLyricsAsync(StorageFile file)
    {
        // Validate parameters first
        if (file == null)
        {
            System.Diagnostics.Debug.WriteLine("[LyricsService] LoadEmbeddedLyricsAsync: file is null");
            return null;
        }

        // Capture file properties while still on UI thread
        string? fileName = null;
        string? filePath = null;
        bool isAvailable = false;
        
        try
        {
            fileName = file.Name;
            filePath = file.Path;
            isAvailable = file.IsAvailable;
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"[LyricsService] LoadEmbeddedLyricsAsync: Error accessing file properties: {ex.Message}");
            return null;
        }

        System.Diagnostics.Debug.WriteLine($"[LyricsService] LoadEmbeddedLyricsAsync: file.Name = {fileName}, IsAvailable = {isAvailable}");

        try
        {
            if (!isAvailable)
            {
                System.Diagnostics.Debug.WriteLine("[LyricsService] LoadEmbeddedLyricsAsync: file is not available");
                return null;
            }

            // Open stream for reading
            using var stream = await file.OpenStreamForReadAsync();
            var name = string.IsNullOrEmpty(filePath) ? fileName! : filePath;
            
            // Create TagLib file with stream abstraction
            var fileAbstract = new StreamAbstraction(name, stream);
            using var tagFile = TagLib.File.Create(fileAbstract, ReadStyle.PictureLazy);

            string? lyricsContent = null;

            // Try to get lyrics from various tags
            if (tagFile.Tag.Lyrics != null && !string.IsNullOrWhiteSpace(tagFile.Tag.Lyrics))
            {
                lyricsContent = tagFile.Tag.Lyrics;
                System.Diagnostics.Debug.WriteLine("[LyricsService] LoadEmbeddedLyricsAsync: found lyrics in LYRICS tag");
            }
            else if (tagFile.Tag.Comment != null && !string.IsNullOrWhiteSpace(tagFile.Tag.Comment))
            {
                lyricsContent = tagFile.Tag.Comment;
                System.Diagnostics.Debug.WriteLine("[LyricsService] LoadEmbeddedLyricsAsync: found lyrics in COMMENT tag");
            }

            if (string.IsNullOrWhiteSpace(lyricsContent))
            {
                System.Diagnostics.Debug.WriteLine("[LyricsService] LoadEmbeddedLyricsAsync: no embedded lyrics found in file");
                return null;
            }

            System.Diagnostics.Debug.WriteLine($"[LyricsService] LoadEmbeddedLyricsAsync: lyrics content length = {lyricsContent.Length}");
            
            var result = ParseLrc(lyricsContent);
            System.Diagnostics.Debug.WriteLine($"[LyricsService] LoadEmbeddedLyricsAsync: result = {(result != null ? $"{result.Lines.Count} lines" : "null")}");
            return result;
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"[LyricsService] LoadEmbeddedLyricsAsync exception: {ex.Message}");
            System.Diagnostics.Debug.WriteLine($"[LyricsService] Stack trace: {ex.StackTrace}");
            return null;
        }
    }
}
