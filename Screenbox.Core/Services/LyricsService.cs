#nullable enable

using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text.RegularExpressions;

namespace Screenbox.Core.Services;

public class LyricLine
{
    public TimeSpan Time { get; set; }
    public string Text { get; set; } = string.Empty;
}

public class Lyrics
{
    public string? Title { get; set; }
    public string? Artist { get; set; }
    public string? Album { get; set; }
    public List<LyricLine> Lines { get; set; } = new();
}

public interface ILyricsService
{
    Lyrics? ParseLrc(string content);
    Lyrics? LoadLyricsFile(string filePath);
}

public class LyricsService : ILyricsService
{
    private static readonly Regex LrcLineRegex = new(@"\[(\d{2}):(\d{2})\.(\d{2,3})\](.*)", RegexOptions.Compiled);
    private static readonly Regex MetaRegex = new(@"\[(ti|ar|al|au|length|by|offset):(.+)\]", RegexOptions.Compiled);

    public Lyrics? ParseLrc(string content)
    {
        if (string.IsNullOrWhiteSpace(content))
            return null;

        var lyrics = new Lyrics();
        var lines = content.Split(new[] { "\r\n", "\r", "\n" }, StringSplitOptions.None);

        foreach (var line in lines)
        {
            var trimmedLine = line.Trim();
            if (string.IsNullOrEmpty(trimmedLine))
                continue;

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

            var lrcMatches = LrcLineRegex.Matches(trimmedLine);
            if (lrcMatches.Count > 0)
            {
                var text = lrcMatches[lrcMatches.Count - 1].Groups[4].Value.Trim();
                foreach (Match match in lrcMatches)
                {
                    var minutes = int.Parse(match.Groups[1].Value);
                    var seconds = int.Parse(match.Groups[2].Value);
                    var millisecondsStr = match.Groups[3].Value;
                    var milliseconds = int.Parse(millisecondsStr.PadRight(3, '0'));
                    
                    if (millisecondsStr.Length == 2)
                        milliseconds *= 10;

                    var time = new TimeSpan(0, 0, minutes, seconds, milliseconds);
                    lyrics.Lines.Add(new LyricLine { Time = time, Text = text });
                }
            }
        }

        return lyrics.Lines.Count > 0 ? lyrics : null;
    }

    public Lyrics? LoadLyricsFile(string filePath)
    {
        try
        {
            if (!File.Exists(filePath))
                return null;

            var content = File.ReadAllText(filePath);
            return ParseLrc(content);
        }
        catch
        {
            return null;
        }
    }
}
