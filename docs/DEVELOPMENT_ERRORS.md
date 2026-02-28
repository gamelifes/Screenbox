# 开发错误记录 (Development Error Log)

本文档记录开发过程中遇到的错误，供后续开发参考。

---

## 1. XAML 属性顺序错误

**日期**: 2026-02-28

**问题**: XAML Styler 校验失败，属性顺序不符合规范

**错误日志位置**: `C:\Users\li/fixlog.md`

**原因**: XAML 属性应按特定顺序排列：
1. `x:Name`
2. 布局属性 (`HorizontalAlignment`, `VerticalAlignment`, `Margin`, `Padding`, `MaxWidth` 等)
3. 外观属性 (`FontSize`, `FontWeight`, `Foreground`, `Opacity` 等)
4. 内容属性 (`Text`, `TextAlignment`, `TextWrapping` 等)

**修复方法**: 
- 使用 `dotnet tool run xstyler format <file>` 自动格式化
- 或手动调整属性顺序

**相关文件**:
- `Screenbox/Pages/PlayerPage.xaml`

**常见错误模式**:
```xaml
<!-- 错误: Opacity 在 TextWrapping 之后 -->
<TextBlock Text="Hello" TextWrapping="Wrap" Opacity="0.5" />

<!-- 正确: Opacity 在 TextWrapping 之前 -->
<TextBlock Text="Hello" Opacity="0.5" TextWrapping="Wrap" />

<!-- 错误: Margin 在 TextWrapping 之后 -->
<TextBlock Text="Hello" TextWrapping="Wrap" Margin="0,8,0,8" />

<!-- 正确: Margin 在 TextWrapping 之前 -->
<TextBlock Text="Hello" Margin="0,8,0,8" TextWrapping="Wrap" />

<!-- 错误: Padding 在 CornerRadius 之后 -->
<Border CornerRadius="8" Padding="24,16">...</Border>

<!-- 正确: Padding 在 CornerRadius 之前 -->
<Border Padding="24,16" CornerRadius="8">...</Border>

<!-- 错误: MaxWidth 在 TextWrapping 之后 -->
<TextBlock HorizontalAlignment="Center" TextWrapping="Wrap" MaxWidth="800" />

<!-- 正确: MaxWidth 在 HorizontalAlignment 之后，TextWrapping 之前 -->
<TextBlock HorizontalAlignment="Center" MaxWidth="800" TextWrapping="Wrap" />
```

---

## 2. 命名空间冲突 - File 类歧义

**日期**: 2026-02-28

**问题**: 构建失败，编译错误 CS0104

**错误信息**:
```
error CS0104: 'File' is an ambiguous reference between 'System.IO.File' and 'TagLib.File'
```

**原因**: 
- 添加 `using TagLib;` 后，`File` 类名产生歧义
- `System.IO.File` 和 `TagLib.File` 都可以简称为 `File`

**修复方法**:
- 明确使用完整命名空间: `System.IO.File.Exists()`
- 或在代码中区分使用

**相关文件**:
- `Screenbox.Core/Services/LyricsService.cs`

**修复代码**:
```csharp
// 修复前
if (!File.Exists(filePath))
    return null;
var content = File.ReadAllText(filePath);

// 修复后
if (!System.IO.File.Exists(filePath))
    return null;
var content = System.IO.File.ReadAllText(filePath);
```

---

## 3. 歌词功能闪退 - ParseLrc 解析异常

**日期**: 2026-02-28

**问题**: 应用安装后闪退

**原因**: 
- `LyricsService.ParseLrc()` 方法中使用 `int.Parse()` 解析 LRC 文件时间戳
- 当 LRC 文件格式异常、空文件或包含无效数据时，抛出 `FormatException` 导致崩溃

**修复方法**:
- 使用 `int.TryParse()` 代替 `int.Parse()`
- 解析失败时跳过该行而不是抛出异常

**相关文件**:
- `Screenbox.Core/Services/LyricsService.cs`

**修复代码**:
```csharp
// 修复前
var minutes = int.Parse(match.Groups[1].Value);
var seconds = int.Parse(match.Groups[2].Value);

// 修复后
if (!int.TryParse(match.Groups[1].Value, out int minutes) ||
    !int.TryParse(match.Groups[2].Value, out int seconds))
{
    continue;
}
```

---

## 开发注意事项

### 添加新 NuGet 包引用时
1. 检查是否有类名与 .NET 框架类名冲突
2. 使用完整命名空间或别名避免歧义

### 修改 XAML 文件时
1. 运行 XAML Styler 格式化工具
2. 遵守属性顺序规范

### 添加解析类时
1. 使用 `TryParse` 代替 `Parse` 处理用户输入
2. 添加完整的异常处理
3. 避免直接抛出异常导致应用崩溃

### XAML 属性顺序规范
**必须遵循的顺序**:
1. `x:Name` (第一个)
2. **布局属性**: `Grid.Row`, `Grid.Column`, `Margin`, `Padding`, `HorizontalAlignment`, `VerticalAlignment`, `MaxWidth`, `MinWidth` 等
3. **外观属性**: `Background`, `Foreground`, `FontSize`, `FontWeight`, `Opacity`, `CornerRadius` 等
4. **内容属性**: `Text`, `TextAlignment`, `TextWrapping`, `ToolTipService.ToolTip` 等
5. **事件属性**: `Click`, `Command`, `Loaded` 等

**关键规则**:
- `Opacity` 必须放在 `TextWrapping` 之前
- `Margin` 必须放在 `TextWrapping` 之前
- `Padding` 必须放在 `CornerRadius` 之后
- `MaxWidth`/`MinWidth` 必须放在 `HorizontalAlignment` 之后，在 `TextWrapping` 之前

---

## 相关工具命令

```bash
# XAML 格式化
dotnet tool run xstyler format <file>

# 构建项目 (需要 .NET SDK)
dotnet build <project>.csproj
```
