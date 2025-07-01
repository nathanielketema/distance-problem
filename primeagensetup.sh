#!/bin/bash

# ThePrimeagen Setup Installation Script for Ubuntu
# Excludes DVORAK keyboard settings as requested

set -e

echo "🚀 Installing ThePrimeagen's Development Setup for Ubuntu"
echo "================================================="

# Update system
echo "📦 Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install essential packages
echo "📦 Installing essential packages..."
sudo apt install -y \
    curl \
    wget \
    git \
    build-essential \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    unzip \
    ripgrep \
    fd-find \
    tmux \
    zsh \
    i3 \
    i3status \
    i3lock \
    dmenu \
    feh \
    xclip \
    nodejs \
    npm

# Install Alacritty
echo "🖥️  Installing Alacritty terminal..."
sudo add-apt-repository ppa:aslatter/ppa -y
sudo apt update
sudo apt install -y alacritty

# Install Neovim (latest stable)
echo "📝 Installing Neovim..."
wget https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz
sudo tar -C /opt -xzf nvim-linux64.tar.gz
sudo ln -sf /opt/nvim-linux64/bin/nvim /usr/local/bin/nvim
rm nvim-linux64.tar.gz

# Install FZF
echo "🔍 Installing FZF..."
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install --all

# Install Oh My Zsh
echo "🐚 Installing Oh My Zsh..."
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Install Zsh plugins
echo "🔌 Installing Zsh plugins..."
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# Install PowerLevel10k theme
echo "🎨 Installing PowerLevel10k theme..."
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

# Create directories
echo "📁 Creating configuration directories..."
mkdir -p ~/.config/{nvim,alacritty,i3,i3status}
mkdir -p ~/.local/{bin,scripts}

# Clone ThePrimeagen's dotfiles for reference
echo "📥 Cloning ThePrimeagen's dotfiles..."
git clone https://github.com/ThePrimeagen/.dotfiles.git ~/primeagen-dotfiles

echo "✅ Base installation complete!"
echo "🔧 Now configuring individual components..."

# Configure Tmux
echo "🖥️  Configuring Tmux..."
cat > ~/.tmux.conf << 'EOF'
set -ga terminal-overrides ",screen-256color*:Tc"
set-option -g default-terminal "screen-256color"
set -s escape-time 0

unbind C-b
set-option -g prefix C-a
bind-key C-a send-prefix
set -g status-style 'bg=#333333 fg=#5eacd3'

bind r source-file ~/.tmux.conf
set -g base-index 1

set-window-option -g mode-keys vi
bind -T copy-mode-vi v send-keys -X begin-selection
bind -T copy-mode-vi y send-keys -X copy-pipe-and-cancel 'xclip -in -selection clipboard'

# vim-like pane switching
bind -r ^ last-window
bind -r k select-pane -U
bind -r j select-pane -D
bind -r h select-pane -L
bind -r l select-pane -R

# ThePrimeagen's sessionizer binding
bind-key -r f run-shell "tmux neww ~/.local/scripts/tmux-sessionizer"
EOF

# Create tmux-sessionizer script
echo "📜 Creating tmux-sessionizer script..."
cat > ~/.local/scripts/tmux-sessionizer << 'EOF'
#!/usr/bin/env bash

if [[ $# -eq 1 ]]; then
    selected=$1
else
    selected=$(find ~/work ~/projects ~/ ~/personal -mindepth 1 -maxdepth 1 -type d 2>/dev/null | fzf)
fi

if [[ -z $selected ]]; then
    exit 0
fi

selected_name=$(basename "$selected" | tr . _)
tmux_running=$(pgrep tmux)

if [[ -z $TMUX ]] && [[ -z $tmux_running ]]; then
    tmux new-session -s $selected_name -c $selected
    exit 0
fi

if ! tmux has-session -t=$selected_name 2> /dev/null; then
    tmux new-session -ds $selected_name -c $selected
fi

tmux switch-client -t $selected_name
EOF

chmod +x ~/.local/scripts/tmux-sessionizer

# Configure Neovim
echo "📝 Configuring Neovim..."
mkdir -p ~/.config/nvim/lua/custom
mkdir -p ~/.config/nvim/after/plugin

# Neovim init.lua
cat > ~/.config/nvim/init.lua << 'EOF'
require("custom")
EOF

# Custom init
cat > ~/.config/nvim/lua/custom/init.lua << 'EOF'
require("custom.remap")
require("custom.packer")
EOF

# Key remaps
cat > ~/.config/nvim/lua/custom/remap.lua << 'EOF'
vim.g.mapleader = " "
vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)

-- ThePrimeagen's tmux-sessionizer binding
vim.keymap.set("n", "<C-f>", "<cmd>silent !tmux neww tmux-sessionizer<CR>")
EOF

# Packer configuration
cat > ~/.config/nvim/lua/custom/packer.lua << 'EOF'
vim.cmd [[packadd packer.nvim]]

return require('packer').startup(function(use)
  use 'wbthomason/packer.nvim'
  
  use {
    'nvim-telescope/telescope.nvim', tag = '0.1.2',
    requires = { {'nvim-lua/plenary.nvim'} }
  }
  
  use({ 'rose-pine/neovim', as = 'rose-pine' })
  
  use {
    'nvim-treesitter/nvim-treesitter',
    run = ':TSUpdate'
  }
  
  use 'ThePrimeagen/harpoon'
  use 'mbbill/undotree'
  use 'tpope/vim-fugitive'
  
  use {
    'VonHeikemen/lsp-zero.nvim',
    branch = 'v2.x',
    requires = {
      {'neovim/nvim-lspconfig'},
      {'williamboman/mason.nvim'},
      {'williamboman/mason-lspconfig.nvim'},
      {'hrsh7th/nvim-cmp'},
      {'hrsh7th/cmp-nvim-lsp'},
      {'L3MON4D3/LuaSnip'},
    }
  }
end)
EOF

# Telescope configuration
cat > ~/.config/nvim/after/plugin/telescope.lua << 'EOF'
local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>pf', builtin.find_files, {})
vim.keymap.set('n', '<C-p>', builtin.git_files, {})
vim.keymap.set('n', '<leader>ps', function()
    builtin.grep_string({ search = vim.fn.input("Grep > ") })
end)
EOF

# Colors configuration
cat > ~/.config/nvim/after/plugin/colors.lua << 'EOF'
function ColorMyPencils(color)
    color = color or "rose-pine"
    vim.cmd.colorscheme(color)
    
    vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
    vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
end

ColorMyPencils()
EOF

# Harpoon configuration
cat > ~/.config/nvim/after/plugin/harpoon.lua << 'EOF'
local mark = require("harpoon.mark")
local ui = require("harpoon.ui")

vim.keymap.set("n", "<leader>a", mark.add_file)
vim.keymap.set("n", "<C-e>", ui.toggle_quick_menu)

vim.keymap.set("n", "<C-h>", function() ui.nav_file(1) end)
vim.keymap.set("n", "<C-t>", function() ui.nav_file(2) end)
vim.keymap.set("n", "<C-n>", function() ui.nav_file(3) end)
vim.keymap.set("n", "<C-s>", function() ui.nav_file(4) end)
EOF

# Treesitter configuration
cat > ~/.config/nvim/after/plugin/treesitter.lua << 'EOF'
require'nvim-treesitter.configs'.setup {
  ensure_installed = { "vimdoc", "javascript", "typescript", "c", "lua", "vim", "vimdoc", "query", "python", "rust", "go" },
  sync_install = false,
  auto_install = true,
  highlight = {
    enable = true,
    additional_vim_regex_highlighting = false,
  },
}
EOF

# Configure Alacritty
echo "🖥️  Configuring Alacritty..."
cat > ~/.config/alacritty/alacritty.yml << 'EOF'
window:
  opacity: 0.9
  padding:
    x: 10
    y: 10

font:
  normal:
    family: "Ubuntu Mono"
    style: Regular
  bold:
    family: "Ubuntu Mono"
    style: Bold
  italic:
    family: "Ubuntu Mono"
    style: Italic
  size: 14.0

colors:
  primary:
    background: '#1a1a1a'
    foreground: '#f8f8f2'
  normal:
    black:   '#000000'
    red:     '#ff5555'
    green:   '#50fa7b'
    yellow:  '#f1fa8c'
    blue:    '#bd93f9'
    magenta: '#ff79c6'
    cyan:    '#8be9fd'
    white:   '#bfbfbf'
EOF

# Configure i3
echo "🪟 Configuring i3 window manager..."
cat > ~/.config/i3/config << 'EOF'
# i3 config file (v4)
set $mod Mod1

# Font for window titles
font pango:Ubuntu Mono 12

# Use Mouse+$mod to drag floating windows
floating_modifier $mod

# Start a terminal
bindsym $mod+Return exec alacritty

# Kill focused window
bindsym $mod+Shift+q kill

# Start dmenu
bindsym $mod+d exec dmenu_run

# Change focus
bindsym $mod+j focus left
bindsym $mod+k focus down
bindsym $mod+l focus up
bindsym $mod+semicolon focus right

# Move focused window
bindsym $mod+Shift+j move left
bindsym $mod+Shift+k move down
bindsym $mod+Shift+l move up
bindsym $mod+Shift+semicolon move right

# Split in horizontal orientation
bindsym $mod+h split h

# Split in vertical orientation
bindsym $mod+v split v

# Enter fullscreen mode
bindsym $mod+f fullscreen toggle

# ThePrimeagen's workspace bindings
bindsym $mod+1 workspace 1
bindsym $mod+2 workspace 2
bindsym $mod+3 workspace 3
bindsym $mod+4 workspace 4
bindsym $mod+5 workspace 5
bindsym $mod+6 workspace 6
bindsym $mod+7 workspace 7
bindsym $mod+8 workspace 8
bindsym $mod+9 workspace 9

# Move focused container to workspace
bindsym $mod+Shift+1 move container to workspace 1
bindsym $mod+Shift+2 move container to workspace 2
bindsym $mod+Shift+3 move container to workspace 3
bindsym $mod+Shift+4 move container to workspace 4
bindsym $mod+Shift+5 move container to workspace 5
bindsym $mod+Shift+6 move container to workspace 6
bindsym $mod+Shift+7 move container to workspace 7
bindsym $mod+Shift+8 move container to workspace 8
bindsym $mod+Shift+9 move container to workspace 9

# Reload the configuration file
bindsym $mod+Shift+c reload

# Restart i3 inplace
bindsym $mod+Shift+r restart

# Exit i3
bindsym $mod+Shift+e exec "i3-nagbar -t warning -m 'You pressed the exit shortcut. Do you really want to exit i3?' -b 'Yes, exit i3' 'i3-msg exit'"

# Status bar
bar {
    status_command i3status
    position top
}
EOF

# Configure Zsh
echo "🐚 Configuring Zsh..."
sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' ~/.zshrc
sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting web-search)/' ~/.zshrc

# Add custom aliases and functions
cat >> ~/.zshrc << 'EOF'

# ThePrimeagen inspired aliases
alias vim="nvim"
alias vi="nvim"
alias tmux-sessionizer="~/.local/scripts/tmux-sessionizer"

# Add local scripts to PATH
export PATH="$HOME/.local/scripts:$PATH"

# FZF configuration
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
EOF

# Set Zsh as default shell
echo "🐚 Setting Zsh as default shell..."
sudo chsh -s $(which zsh) $USER

echo "✅ Configuration complete!"
echo ""
echo "🎉 ThePrimeagen's setup has been installed!"
echo ""
echo "📋 Next steps:"
echo "1. Log out and log back in (or reboot) to start using i3"
echo "2. Open Neovim and run :PackerSync to install plugins"
echo "3. Run 'p10k configure' to set up PowerLevel10k theme"
echo "4. Create ~/work, ~/projects, ~/personal directories for tmux-sessionizer"
echo ""
echo "🔥 Key bindings:"
echo "- Ctrl+F: tmux-sessionizer (from anywhere)"
echo "- Space+pv: Open file explorer in Neovim"
echo "- Space+pf: Find files with Telescope"
echo "- Ctrl+P: Find git files with Telescope"
echo "- Space+a: Add file to Harpoon"
echo "- Ctrl+E: Toggle Harpoon menu"
echo "- Alt+1-9: Switch i3 workspaces"
echo ""
echo "🚀 You're now ready to code like ThePrimeagen!"
