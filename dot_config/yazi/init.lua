require("git"):setup({
    order = 1500,
})

require("starship"):setup({
    config_file = "~/.config/starship_yazi.toml",
    hide_flags = true,
})
