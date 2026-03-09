#nullable enable

using CommunityToolkit.Mvvm.Messaging.Messages;

namespace Screenbox.Core.Messages;

/// <summary>
/// 画中画（Compact Layout）模式变化消息
/// </summary>
public sealed class CompactLayoutChangedMessage : ValueChangedMessage<bool>
{
    public CompactLayoutChangedMessage(bool isCompact) : base(isCompact)
    {
    }
}
