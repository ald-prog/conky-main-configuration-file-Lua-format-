# conky-main-configuration-file-Lua-format-
conky configuratuion with lua format
mkdir -p "$HOME/.config/conky"
CONKY_RC_PATH="$HOME/.config/conky/conky.conf\ conky.lua"

# Running the conky disk temperature data extractor:

sudo visudo

Add:

yourusername ALL=(ALL) NOPASSWD: /usr/sbin/smartctl
yourusername ALL=(ALL) NOPASSWD: /usr/sbin/hddtemp
