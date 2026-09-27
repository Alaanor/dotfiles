//@ pragma IconTheme Papirus-Dark
import Quickshell
import qs.dashboard
import qs.launcher
import qs.screenshot

ShellRoot {
    Dashboard {}
    Screenshot {}
    AppLauncher { id: launcher; onShown: emoji.close() }
    EmojiPicker { id: emoji; onShown: launcher.close() }
}
