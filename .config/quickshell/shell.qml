//@ pragma IconTheme Papirus-Dark
import Quickshell
import qs.dashboard
import qs.dictate
import qs.launcher
import qs.screenshot

ShellRoot {
    Dashboard {}
    Screenshot {}
    Dictate {}
    AppLauncher { id: launcher; onShown: emoji.close() }
    EmojiPicker { id: emoji; onShown: launcher.close() }
}
