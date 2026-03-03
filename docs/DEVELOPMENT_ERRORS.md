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

<!-- 错误: Margin 在 HorizontalAlignment 之后 -->
<TextBlock HorizontalAlignment="Center" Margin="0,8,0,8" TextWrapping="Wrap" />

<!-- 正确: Margin 在 HorizontalAlignment 之前 -->
<TextBlock Margin="0,8,0,8" HorizontalAlignment="Center" TextWrapping="Wrap" />

<!-- 错误: Padding 在 HorizontalAlignment 之后 -->
<Border HorizontalAlignment="Center" Padding="24,16" CornerRadius="8">...</Border>

<!-- 正确: Padding 在 HorizontalAlignment 之前 -->
<Border Padding="24,16" HorizontalAlignment="Center" CornerRadius="8">...</Border>

<!-- 错误: MaxWidth 在 TextWrapping 之后 -->
<TextBlock HorizontalAlignment="Center" TextWrapping="Wrap" MaxWidth="800" />

<!-- 正确: MaxWidth 在 HorizontalAlignment 之前，TextWrapping 之前 -->
<TextBlock MaxWidth="800" HorizontalAlignment="Center" TextWrapping="Wrap" />
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
- `Margin` 必须放在 `HorizontalAlignment` 之前
- `Padding` 必须放在 `HorizontalAlignment` 之前
- `MaxWidth`/`MinWidth` 必须放在 `HorizontalAlignment` 之前，在 `TextWrapping` 之前

---

## 4. XAML 解析错误 - 标签嵌套不匹配

**日期**: 2026-02-28

**问题**: 构建失败，XAML 解析错误

**错误信息**:
```
Xaml Xml Parsing Error error WMC9997: 
The 'Button' start tag on line 505 position 10 does not match the end tag of 'Grid'. 
Line 529, position 11.
```

**原因**: XAML 文件中存在重复的标签元素，导致开始标签和结束标签不匹配

**修复方法**: 
- 检查并删除重复的 XAML 元素
- 确保每个开始标签都有对应的结束标签
- 使用正确的嵌套结构

**相关文件**:
- `Screenbox/Pages/PlayerPage.xaml`

---

## 5. C# 语法错误 - 缺少闭合大括号

**日期**: 2026-03-03

**问题**: 构建失败，编译错误 CS1513 或 CS1514

**错误信息**:
```
error CS1513: } expected
error CS1514: { expected
```

**原因**:
- 代码中 if 语句块缺少闭合大括号 `}`
- 导致后续代码无法到达，且语法不完整

**相关文件**:
- `Screenbox.Core/Services/LyricsService.cs` (第46-51行)

**问题代码**:
```csharp
// 错误: if 语句块缺少闭合大括号
if (string.IsNullOrWhiteSpace(content))
{
    System.Diagnostics.Debug.WriteLine("[LyricsService] ParseLrc: content is null or empty, returning null");
    return null;
    var lyrics = new Lyrics();  // ❌ 无法到达的代码
}

var lyrics = new Lyrics();  // ❌ 缩进错误
```

**修复代码**:
```csharp
// 修复后: 添加闭合大括号
if (string.IsNullOrWhiteSpace(content))
{
    System.Diagnostics.Debug.WriteLine("[LyricsService] ParseLrc: content is null or empty, returning null");
    return null;
}

var lyrics = new Lyrics();
```

**验证方法**:
```bash
# 检查大括号是否平衡
echo "Open braces: $(grep -o '{' <file> | wc -l), Close braces: $(grep -o '}' <file> | wc -l)"
```

**防范措施**:
1. 编写代码时确保每个 `{` 都有对应的 `}`
2. 使用代码格式化工具 (Ctrl+K, Ctrl+E) 自动规范化代码
3. 提交前运行构建验证
4. 注意: return 语句后的代码如果逻辑上不应执行，需要检查是否缺少大括号

---

## 6. UWP 线程错误 - StorageFile 跨线程访问异常

**日期**: 2026-03-03

**问题**: 点击歌曲时应用崩溃

**错误信息**:
```
引发的异常:"System.Exception"(位于 Screenbox.exe 中)
"System.Exception"类型的未经处理的异常在 Screenbox.exe 中发生
应用程序调用一个已为另一线程整理的接口。
(Exception from HRESULT: 0x8001010E (RPC_E_WRONG_THREAD))
```

**原因**:
- UWP的 `StorageFile` 对象具有**线程亲和性**
- 其**所有属性**（`Name`, `Path`, `IsAvailable` 等）只能在创建它的UI线程上访问
- 当异步方法中的 `await` 切换到后台线程后，再访问这些属性就会抛出此异常

**相关文件**:
- `Screenbox.Core/Services/LyricsService.cs` (第158-176行)

**问题代码**:
```csharp
// 错误: await后访问StorageFile属性会报错
public async Task<Lyrics?> LoadEmbeddedLyricsAsync(StorageFile file)
{
    // 此时在UI线程
    var fileName = file.Name;    // ✅ OK
    var filePath = file.Path;    // ✅ OK
    
    using var stream = await file.OpenStreamForReadAsync(); // await后切换到后台线程
    
    // ❌ 以下访问都会报错！
    if (!file.IsAvailable) { }     // RPC_E_WRONG_THREAD!
    var path = file.Path;         // RPC_E_WRONG_THREAD!
    var name = file.Name;         // RPC_E_WRONG_THREAD!
}
```

**修复代码**:
```csharp
// 修复后: 在await前捕获**所有**需要的属性
public async Task<Lyrics?> LoadEmbeddedLyricsAsync(StorageFile file)
{
    // ✅ 在await前捕获所有属性（必须在UI线程）
    var fileName = file.Name;
    var filePath = file.Path;
    var isAvailable = file.IsAvailable;  // 别忘了这个！
    System.Diagnostics.Debug.WriteLine($"file.Name = {fileName}");
    
    if (!isAvailable) { return null; }  // ✅ 使用已捕获的值
    
    using var stream = await file.OpenStreamForReadAsync();
    var name = string.IsNullOrEmpty(filePath) ? fileName : filePath; // ✅ 使用已捕获的值
}
```

**关键点**: 容易遗漏的属性！
| 属性 | 线程安全 | 说明 |
|------|---------|------|
| `Name` | ❌ 需提前捕获 | 文件名 |
| `Path` | ❌ 需提前捕获 | 文件路径 |
| `IsAvailable` | ❌ **极易遗漏** | 文件是否可用 |
| `ContentType` | ❌ 需提前捕获 | MIME类型 |
| `DateCreated` | ❌ 需提前捕获 | 创建时间 |

**防范措施**:
1. **提前捕获所有值**: 在第一个 `await` 前捕获**所有**需要的属性，包括 `IsAvailable`
2. **使用临时变量**: 将捕获的值存入临时变量，后续使用变量而非访问对象属性
3. **代码审查**: 检查所有 `StorageFile`/`StorageFolder` 的访问是否在 await 之前
4. **使用Dispatcher**: 如需在后台线程更新UI，使用 `CoreDispatcher.RunAsync`
5. **单元测试**: 在多线程环境下测试存储文件操作

**常见具有线程亲和性的UWP对象**:
- `StorageFile`, `StorageFolder` - 所有属性都有线程亲和性
- `StorageItem` 派生类
- UI控件及其属性

---

## 7. VLC 事件后台线程访问 - UI 线程错误

**日期**: 2026-03-03

**问题**: 播放歌曲时应用崩溃

**错误信息**:
```
Screenbox.exe!Screenbox.Pages.PlayerPage.ViewModel.get() 行 39
Screenbox.exe!Screenbox.Pages.PlayerPage.MediaPlayer_PositionChanged 行 86
Screenbox.Core.dll!Screenbox.Core.Playback.VlcMediaPlayer.VlcPlayer_TimeChanged 行 343

System.Exception: 应用程序调用一个已为另一线程整理的接口。
(Exception from HRESULT: 0x8001010E (RPC_E_WRONG_THREAD))
```

**原因**:
- VLC 的 `TimeChanged` 事件在**后台线程**（LibVLC 内部线程）上触发
- 事件处理程序直接在后台线程调用 ViewModel 的属性更新方法
- 这导致 UI 属性更新在非 UI 线程上执行，抛出 `RPC_E_WRONG_THREAD` 错误

**相关文件**:
- `Screenbox/Pages/PlayerPage.xaml.cs` (第84-91行)

**问题代码**:
```csharp
// 错误: VLC 事件在后台线程触发，直接访问 ViewModel 会报错
private void MediaPlayer_PositionChanged(IMediaPlayer sender, ValueChangedEventArgs<TimeSpan> args)
{
    ViewModel.UpdateLyricsPosition(args.NewValue);  // ❌ 后台线程访问 UI 属性
}
```

**修复代码**:
```csharp
// 修复后: 使用 Dispatcher.RunAsync 切换到 UI 线程
private async void MediaPlayer_PositionChanged(IMediaPlayer sender, ValueChangedEventArgs<TimeSpan> args)
{
    // ✅ 将回调调度到 UI 线程
    await Dispatcher.RunAsync(CoreDispatcherPriority.Normal, () =>
    {
        ViewModel.UpdateLyricsPosition(args.NewValue);
    });
}
```

**防范措施**:
1. **始终假设事件在后台线程**: 特别是第三方库（VLC, FFmpeg 等）的事件回调
2. **使用 Dispatcher**: 所有 UI 更新都必须通过 `Dispatcher.RunAsync` 切换到 UI 线程
3. **使用 async void**: 事件处理程序使用 `async void` 以支持 await
4. **检查线程亲和性**: 访问 UI 元素前先确认是否在 UI 线程

**常见在后台线程触发的事件**:
- LibVLCSharp 媒体播放事件（TimeChanged, PositionChanged 等）
- 网络请求回调
- 文件系统监视器事件
- 硬件传感器事件

---

## 8. UWP 文件访问 - 传统 .NET IO API 在 UWP 中不可用

**日期**: 2026-03-03

**问题**: 外部 LRC 文件无法加载，日志显示 `file does not exist`

**错误现象**:
```
[PlayerPageViewModel] LoadLyrics: folder path = 'C:\Users\Admin\Music'
[PlayerPageViewModel] LoadLyrics: found LRC file: C:\Users\Admin\Music\song.lrc
[LyricsService] LoadLyricsFile: file does not exist
```

**原因**:
- UWP (Universal Windows Platform) 应用运行在受限的 AppContainer 环境中
- 传统的 `System.IO.File.Exists()`、`Directory.Exists()`、`File.ReadAllText()` 等 API 在 UWP 中**无法直接访问用户文件系统**
- 需要使用 Windows.Storage API 来访问文件

**相关文件**:
- `Screenbox.Core/ViewModels/PlayerPageViewModel.cs`

**问题代码**:
```csharp
// 错误: 传统 .NET IO API 在 UWP 中无法访问用户文件
string? dir = Path.GetDirectoryName(mediaPath);
if (Directory.Exists(dir))  // ❌ UWP 中返回 false
{
    string[] lrcFiles = Directory.GetFiles(dir, "*.lrc");  // ❌ 不工作
    string content = File.ReadAllText(lrcPath);  // ❌ 不工作
}
```

**修复代码**:
```csharp
// 修复后: 使用 Windows Storage API
if (Media?.Source is StorageFile storageFile)
{
    // 获取文件所在文件夹
    StorageFolder? folder = await storageFile.GetParentAsync();
    
    if (folder != null)
    {
        // 使用 StorageFile API 访问文件
        StorageFile lrcFile = await folder.GetFileAsync(lrcFileName);
        string content = await FileIO.ReadTextAsync(lrcFile);
    }
}

// 或使用路径获取 StorageFile
StorageFile lrcFile = await StorageFile.GetFileFromPathAsync(lrcPath);
string content = await FileIO.ReadTextAsync(lrcFile);
```

**UWP 文件访问正确方式**:
| 任务 | 传统 .NET API | UWP API |
|------|---------------|----------|
| 检查文件是否存在 | `File.Exists(path)` | `try { await StorageFile.GetFileFromPathAsync(path) } catch { }` |
| 检查目录是否存在 | `Directory.Exists(path)` | 使用 `StorageFolder.GetParentAsync()` |
| 读取文件内容 | `File.ReadAllText(path)` | `await FileIO.ReadTextAsync(storageFile)` |
| 写入文件 | `File.WriteAllText(path, content)` | `await FileIO.WriteTextAsync(storageFile, content)` |
| 列举文件 | `Directory.GetFiles(path)` | `await folder.GetFilesAsync()` |

**防范措施**:
1. **始终使用 Windows.Storage API**: 在 UWP 应用中不要使用 System.IO
2. **通过 StorageFile 获取路径**: 从 Media.Source (StorageFile) 获取父文件夹
3. **使用异步 API**: 所有 Storage API 都是异步的
4. **处理异常**: 文件可能不存在或无权限访问

---

## 相关工具命令

```bash
# XAML 格式化
dotnet tool run xstyler format <file>

# 构建项目 (需要 .NET SDK)
dotnet build <project>.csproj

# 检查大括号平衡 (Linux/macOS)
echo "Open braces: $(grep -o '{' <file> | wc -l), Close braces: $(grep -o '}' <file> | wc -l)"
```
