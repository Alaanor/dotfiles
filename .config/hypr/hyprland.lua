hl.monitor({ output = "DP-3",     mode = "1920x1080@60",  position = "0x0",    scale = 1 })
hl.monitor({ output = "DP-1",     mode = "2560x1440@240", position = "1920x0", scale = 1 })
hl.monitor({ output = "HDMI-A-1", mode = "1920x1080@60",  position = "4480x0", scale = 1 })

hl.env("XCURSOR_SIZE", "24")

hl.config({
    input = {
        kb_layout  = "ch",
        kb_variant = "fr",
        kb_options = "grp:caps_toggle",
        follow_mouse  = 0,
        sensitivity   = 0.2,
        accel_profile = "flat",
    },
    general = {
        gaps_in  = 5,
        gaps_out = 20,
        border_size = 2,
        col = {
            active_border   = { colors = { "rgba(33ccffee)", "rgba(00ff99ee)" }, angle = 45 },
            inactive_border = "rgba(595959aa)",
        },
        layout = "dwindle",
    },
    decoration = { rounding = 5 },
    animations = { enabled = true },
    dwindle    = { preserve_split = true },
    misc       = { disable_hyprland_logo = true },
})

hl.curve("myBezier", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.05 } } })
hl.animation({ leaf = "windows",     enabled = true, speed = 7,  bezier = "myBezier" })
hl.animation({ leaf = "windowsOut",  enabled = true, speed = 7,  bezier = "default", style = "popin 80%" })
hl.animation({ leaf = "border",      enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 8,  bezier = "default" })
hl.animation({ leaf = "fade",        enabled = true, speed = 7,  bezier = "default" })
hl.animation({ leaf = "workspaces",  enabled = true, speed = 6,  bezier = "default" })

hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
hl.workspace_rule({ workspace = "f[1]",   gaps_out = 0, gaps_in = 0 })
hl.window_rule({ name = "no-gaps-wtv1", match = { float = false, workspace = "w[tv1]" }, border_size = 0, rounding = 0 })
hl.window_rule({ name = "no-gaps-f1",   match = { float = false, workspace = "f[1]" },   border_size = 0, rounding = 0 })

hl.layer_rule({ name = "no-anim-screenshot", match = { namespace = "qs-screenshot.*" }, no_anim = true })

hl.window_rule({ name = "float-jetbrains-commit", match = { class = "jetbrains-rustrover" }, float = true })

local monitors = { "DP-3", "DP-1", "HDMI-A-1" }
for i = 1, 9 do
    hl.workspace_rule({ workspace = tostring(i), monitor = monitors[(i - 1) % 3 + 1] })
end

local mainMod = "SUPER"

hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd("konsole"))
hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("qs ipc call dashboard toggle"))
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd("zlaunch toggle"))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd("zlaunch toggle --modes emojis"))
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd("zlaunch toggle --modes clipboard"))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())

hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "l" }))
hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "r" }))
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "u" }))
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "d" }))

hl.bind(mainMod .. " + SHIFT + H", hl.dsp.window.move({ direction = "l" }))
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.window.move({ direction = "r" }))
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.window.move({ direction = "u" }))
hl.bind(mainMod .. " + SHIFT + J", hl.dsp.window.move({ direction = "d" }))

for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("pactl set-sink-volume @DEFAULT_SINK@ +5%"))
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("pactl set-sink-volume @DEFAULT_SINK@ -5%"))
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("pactl set-sink-mute @DEFAULT_SINK@ toggle"))
hl.bind("XF86AudioPlay",        hl.dsp.exec_cmd("playerctl play-pause"))
hl.bind("XF86AudioNext",        hl.dsp.exec_cmd("playerctl next"))
hl.bind("XF86AudioPrev",        hl.dsp.exec_cmd("playerctl previous"))

hl.bind("ALT + 1", hl.dsp.exec_cmd("qs ipc call screenshot region"))
hl.bind("ALT + 2", hl.dsp.exec_cmd("qs ipc call screenshot delayed 3"))
hl.bind("ALT + 3", hl.dsp.exec_cmd("qs ipc call screenshot record"))
hl.bind("ALT + 4", hl.dsp.exec_cmd("~/bin/ocr"))

hl.bind(mainMod .. " + ALT + D", hl.dsp.exec_cmd("/usr/lib/hyprwhspr/config/hyprland/hyprwhspr-tray.sh record"), { description = "Speech-to-text" })

hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

hl.on("hyprland.start", function()
    hl.exec_cmd("fcitx5")
    hl.exec_cmd("zlaunch")
    hl.exec_cmd("qs")
    hl.exec_cmd("hyprpaper")
    hl.exec_cmd("easyeffects --gapplication-service")
    hl.exec_cmd("setfacl -m u:clanker:x $XDG_RUNTIME_DIR && setfacl -m u:clanker:rw $XDG_RUNTIME_DIR/$WAYLAND_DISPLAY")
end)
