#!/bin/bash

# ThePrimeagen's Development Setup - Clean Installation Script for Ubuntu
# This script performs a complete cleanup and fresh installation

set -e

echo "🧹 Starting CLEAN installation of ThePrimeagen's Development Setup for Ubuntu..."
echo "⚠️  This script will remove existing configurations and start fresh!"
echo "Press Ctrl+C within 10 seconds to cancel..."
sleep 10

# ============================================================================
# CLEANUP PHASE - Remove existing configurations and installations
# ============================================================================

echo "🗑️  Phase 1: Cleaning existing configurations..."

# Stop any running tmux sessions
echo "Stopping tmux sessions..."
tmux kill-server 2>/dev/null || true

# Remove existing configuration directories
echo "Removing existing config directories..."
rm -rf ~/.config/nvim
rm -rf ~/.config/alacritty
rm -rf ~/.config/i3
rm -rf ~/.config/i3status
rm -rf ~/.local/share/nvim
rm -rf ~/.cache/nvim
rm -rf ~/.vim
rm -rf ~/.vimrc
rm -rf ~/.tmux.conf
rm -rf ~/.tmux
rm -rf ~/.local/bin/tmux-sessionizer

# Remove Oh My Zsh and related configurations
echo "Removing existing Zsh configurations..."
rm -rf ~/.oh-my-zsh
rm -rf ~/.zshrc
rm -rf ~/.zsh_history
rm -rf ~/.p10k.zsh

# Remove existing Neovim installations
echo "Removing existing Neovim installations..."
sudo rm -rf /opt/nvim*
sudo rm -rf /usr/local/bin/nvim
sudo rm -rf /usr/bin/nvim

# Remove existing fonts
echo "Removing existing Nerd Fonts..."
rm -rf ~/.local/share/fonts/FiraCode*
rm -rf ~/.local/share/fonts/*Nerd*

# Clean package cache
echo "Cleaning package cache..."
sudo apt autoremove -y
sudo apt autoclean

# Remove potentially conflicting packages
echo "Removing potentially conflicting packages..."
sudo apt remove --purge -y neovim vim-* 2>/dev/null || true
sudo apt remove --purge -y tmux 2>/dev/null || true
sudo apt remove --purge -y zsh 2>/dev/null || true
sudo apt remove --purge -y i3* 2>/dev/null || true
sudo apt remove --purge -y alacritty 2>/dev/null || true

# ============================================================================
# FRESH INSTALLATION PHASE
# ============================================================================

echo "🚀 Phase 2: Fresh installation..."

# Update system
echo "📦 Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install essential packages
echo "🔧 Installing essential packages..."
sudo apt install -y \
    curl \
    wget \
    git \
    build-essential \
    unzip \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    ripgrep \
    fd-find \
    fzf \
    tmux \
    zsh \
    i3 \
    i3status \
    i3lock \
    dmenu \
    xclip \
    fontconfig

# Install Alacritty
echo "💻 Installing Alacritty terminal..."
sudo apt install -y alacritty

# Install Neovim (latest stable) with proper cleanup
echo "📝 Installing Neovim (latest stable)..."
cd /tmp
rm -f nvim-linux-x86_64.tar.gz
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
sudo rm -rf /opt/nvim
sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz

# Create symlink for global access
sudo ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim

# Install Node.js (for Neovim plugins)
echo "🟢 Installing Node.js..."
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install Python support for Neovim
echo "🐍 Installing Python support..."
sudo apt install -y python3-pip
pip3 install --user pynvim

# Install Oh My Zsh (with proper cleanup)
echo "🐚 Installing Oh My Zsh..."
export RUNZSH=no
export CHSH=no
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Install Zsh plugins
echo "🔌 Installing Zsh plugins..."
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# Install PowerLevel10k theme
echo "🎨 Installing PowerLevel10k theme..."
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

# Create directories
echo "📁 Creating directory structure..."
mkdir -p ~/.config/nvim
mkdir -p ~/.config/alacritty
mkdir -p ~/.config/i3
mkdir -p ~/.local/bin
mkdir -p ~/personal
mkdir -p ~/work
mkdir -p ~/.vim/undodir

# Install FiraCode Nerd Font
echo "🔤 Installing FiraCode Nerd Font..."
mkdir -p ~/.local/share/fonts
cd /tmp
rm -f FiraCode.zip
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/FiraCode.zip
unzip -o FiraCode.zip -d FiraCode
cp FiraCode/*.ttf ~/.local/share/fonts/
fc-cache -fv

# Configure Tmux
echo "🖥️  Configuring Tmux..."
cat > ~/.tmux.conf << 'EOF'
# ThePrimeagen's Tmux Configuration

# Set prefix to Ctrl-a
unbind C-b
set-option -g prefix C-a
bind-key C-a send-prefix

# Split panes using | and -
bind | split-window -h
bind - split-window -v
unbind '"'
unbind %

# Switch panes using Alt-arrow without prefix
bind -n M-Left select-pane -L
bind -n M-Right select-pane -R
bind -n M-Up select-pane -U
bind -n M-Down select-pane -D

# Enable mouse mode
set -g mouse on

# Start windows and panes at 1, not 0
set -g base-index 1
setw -g pane-base-index 1

# Reload config file
bind r source-file ~/.tmux.conf \; display-message "Config reloaded!"

# Status bar
set -g status-bg black
set -g status-fg white
set -g status-left-length 20
set -g status-left '#[fg=green][#S] '
set -g status-right '#[fg=yellow]%Y-%m-%d %H:%M'

# Window status
setw -g window-status-current-style 'fg=black bg=white bold'
setw -g window-status-current-format ' #I:#W#F '
setw -g window-status-style 'fg=white'
setw -g window-status-format ' #I:#W#F '

# Pane borders
set -g pane-border-style 'fg=colour238'
set -g pane-active-border-style 'fg=colour51'

# tmux-sessionizer binding
bind-key f run-shell "tmux neww ~/.local/bin/tmux-sessionizer"
EOF

# Create tmux-sessionizer script
echo "🔍 Creating tmux-sessionizer script..."
cat > ~/.local/bin/tmux-sessionizer << 'EOF'
#!/usr/bin/env bash

if [[ $# -eq 1 ]]; then
    selected=$1
else
    selected=$(find ~/work ~/personal ~/work/* ~/personal/* -mindepth 1 -maxdepth 1 -type d 2>/dev/null | fzf)
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
    tmux new-session -d -s $selected_name -c $selected
fi

if [[ -z $TMUX ]]; then
    tmux attach-session -t $selected_name
else
    tmux switch-client -t $selected_name
fi
EOF

chmod +x ~/.local/bin/tmux-sessionizer

# Configure Neovim
echo "📝 Configuring Neovim..."
cat > ~/.config/nvim/init.lua << 'EOF'
-- ThePrimeagen's Neovim Configuration

-- Set leader key
vim.g.mapleader = " "

-- Basic settings
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.wrap = false
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
vim.opt.undofile = true
vim.opt.hlsearch = false
vim.opt.incsearch = true
vim.opt.termguicolors = true
vim.opt.scrolloff = 8
vim.opt.signcolumn = "yes"
vim.opt.isfname:append("@-@")
vim.opt.updatetime = 50
vim.opt.colorcolumn = "80"

-- Key mappings
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")
vim.keymap.set("n", "J", "mzJ`z")
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")
vim.keymap.set("x", "<leader>p", "\"_dP")
vim.keymap.set("n", "<leader>y", "\"+y")
vim.keymap.set("v", "<leader>y", "\"+y")
vim.keymap.set("n", "<leader>Y", "\"+Y")
vim.keymap.set("n", "<leader>d", "\"_d")
vim.keymap.set("v", "<leader>d", "\"_d")
vim.keymap.set("n", "Q", "<nop>")
vim.keymap.set("n", "<C-f>", "<cmd>silent !tmux neww tmux-sessionizer<CR>")
vim.keymap.set("n", "<leader>f", function()
    vim.lsp.buf.format()
end)
vim.keymap.set("n", "<C-k>", "<cmd>cnext<CR>zz")
vim.keymap.set("n", "<C-j>", "<cmd>cprev<CR>zz")
vim.keymap.set("n", "<leader>k", "<cmd>lnext<CR>zz")
vim.keymap.set("n", "<leader>j", "<cmd>lprev<CR>zz")
vim.keymap.set("n", "<leader>s", ":%s/\\<<C-r><C-w>\\>/<C-r><C-w>/gI<Left><Left><Left>")
vim.keymap.set("n", "<leader>x", "<cmd>!chmod +x %<CR>", { silent = true })

-- Install packer if not installed
local ensure_packer = function()
  local fn = vim.fn
  local install_path = fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'
  if fn.empty(fn.glob(install_path)) > 0 then
    fn.system({'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path})
    vim.cmd [[packadd packer.nvim]]
    return true
  end
  return false
end

local packer_bootstrap = ensure_packer()

-- Packer configuration
require('packer').startup(function(use)
  use 'wbthomason/packer.nvim'
  
  -- Telescope
  use {
    'nvim-telescope/telescope.nvim', tag = '0.1.4',
    requires = { {'nvim-lua/plenary.nvim'} }
  }
  
  -- Colorscheme
  use({ 'rose-pine/neovim', as = 'rose-pine' })
  
  -- Treesitter
  use('nvim-treesitter/nvim-treesitter', {run = ':TSUpdate'})
  
  -- Harpoon
  use('theprimeagen/harpoon')
  
  -- Undotree
  use('mbbill/undotree')
  
  -- Git
  use('tpope/vim-fugitive')
  
  -- LSP
  use {
    'VonHeikemen/lsp-zero.nvim',
    branch = 'v3.x',
    requires = {
      {'williamboman/mason.nvim'},
      {'williamboman/mason-lspconfig.nvim'},
      {'neovim/nvim-lspconfig'},
      {'hrsh7th/nvim-cmp'},
      {'hrsh7th/cmp-nvim-lsp'},
      {'L3MON4D3/LuaSnip'},
    }
  }
  
  if packer_bootstrap then
    require('packer').sync()
  end
end)

-- Colorscheme
vim.cmd('colorscheme rose-pine')

-- Telescope setup
local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>pf', builtin.find_files, {})
vim.keymap.set('n', '<C-p>', builtin.git_files, {})
vim.keymap.set('n', '<leader>ps', function()
    builtin.grep_string({ search = vim.fn.input("Grep > ") });
end)

-- Harpoon setup
local mark = require("harpoon.mark")
local ui = require("harpoon.ui")
vim.keymap.set("n", "<leader>a", mark.add_file)
vim.keymap.set("n", "<C-e>", ui.toggle_quick_menu)
vim.keymap.set("n", "<C-h>", function() ui.nav_file(1) end)
vim.keymap.set("n", "<C-t>", function() ui.nav_file(2) end)
vim.keymap.set("n", "<C-n>", function() ui.nav_file(3) end)
vim.keymap.set("n", "<C-s>", function() ui.nav_file(4) end)

-- Undotree
vim.keymap.set('n', '<leader>u', vim.cmd.UndotreeToggle)
EOF

# Configure Alacritty
echo "💻 Configuring Alacritty..."
cat > ~/.config/alacritty/alacritty.yml << 'EOF'
# ThePrimeagen's Alacritty Configuration

window:
  opacity: 0.95
  padding:
    x: 10
    y: 10

font:
  normal:
    family: "FiraCode Nerd Font"
    style: Regular
  bold:
    family: "FiraCode Nerd Font"
    style: Bold
  italic:
    family: "FiraCode Nerd Font"
    style: Italic
  size: 14.0

colors:
  primary:
    background: '#191724'
    foreground: '#e0def4'
  cursor:
    text: '#191724'
    cursor: '#796268'
  normal:
    black: '#26233a'
    red: '#eb6f92'
    green: '#31748f'
    yellow: '#f6c177'
    blue: '#9ccfd8'
    magenta: '#c4a7e7'
    cyan: '#ebbcba'
    white: '#e0def4'
  bright:
    black: '#6e6a86'
    red: '#eb6f92'
    green: '#31748f'
    yellow: '#f6c177'
    blue: '#9ccfd8'
    magenta: '#c4a7e7'
    cyan: '#ebbcba'
    white: '#e0def4'

key_bindings:
  - { key: F, mods: Control, action: ToggleFullscreen }
EOF

# Configure i3
echo "🪟 Configuring i3 window manager..."
cat > ~/.config/i3/config << 'EOF'
# ThePrimeagen's i3 Configuration

# Set mod key (Mod1=<Alt>, Mod4=<Super>)
set $mod Mod4

# Font for window titles
font pango:FiraCode Nerd Font 10

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

# Change container layout
bindsym $mod+s layout stacking
bindsym $mod+w layout tabbed
bindsym $mod+e layout toggle split

# Toggle tiling / floating
bindsym $mod+Shift+space floating toggle

# Change focus between tiling / floating windows
bindsym $mod+space focus mode_toggle

# Focus the parent container
bindsym $mod+a focus parent

# Define names for default workspaces
set $ws1 "1"
set $ws2 "2"
set $ws3 "3"
set $ws4 "4"
set $ws5 "5"
set $ws6 "6"
set $ws7 "7"
set $ws8 "8"
set $ws9 "9"
set $ws10 "10"

# Switch to workspace
bindsym $mod+1 workspace number $ws1
bindsym $mod+2 workspace number $ws2
bindsym $mod+3 workspace number $ws3
bindsym $mod+4 workspace number $ws4
bindsym $mod+5 workspace number $ws5
bindsym $mod+6 workspace number $ws6
bindsym $mod+7 workspace number $ws7
bindsym $mod+8 workspace number $ws8
bindsym $mod+9 workspace number $ws9
bindsym $mod+0 workspace number $ws10

# Move focused container to workspace
bindsym $mod+Shift+1 move container to workspace number $ws1
bindsym $mod+Shift+2 move container to workspace number $ws2
bindsym $mod+Shift+3 move container to workspace number $ws3
bindsym $mod+Shift+4 move container to workspace number $ws4
bindsym $mod+Shift+5 move container to workspace number $ws5
bindsym $mod+Shift+6 move container to workspace number $ws6
bindsym $mod+Shift+7 move container to workspace number $ws7
bindsym $mod+Shift+8 move container to workspace number $ws8
bindsym $mod+Shift+9 move container to workspace number $ws9
bindsym $mod+Shift+0 move container to workspace number $ws10

# Reload the configuration file
bindsym $mod+Shift+c reload

# Restart i3 inplace
bindsym $mod+Shift+r restart

# Exit i3
bindsym $mod+Shift+e exec "i3-nagbar -t warning -m 'You pressed the exit shortcut. Do you really want to exit i3? This will end your X session.' -B 'Yes, exit i3' 'i3-msg exit'"

# Resize window mode
mode "resize" {
    bindsym j resize shrink width 10 px or 10 ppt
    bindsym k resize grow height 10 px or 10 ppt
    bindsym l resize shrink height 10 px or 10 ppt
    bindsym semicolon resize grow width 10 px or 10 ppt
    
    bindsym Return mode "default"
    bindsym Escape mode "default"
    bindsym $mod+r mode "default"
}

bindsym $mod+r mode "resize"

# Status bar
bar {
    status_command i3status
    position top
}

# Window borders
default_border pixel 2
default_floating_border pixel 2

# Colors
client.focused          #9ccfd8 #9ccfd8 #191724 #9ccfd8   #9ccfd8
client.focused_inactive #6e6a86 #6e6a86 #e0def4 #6e6a86   #6e6a86
client.unfocused        #26233a #26233a #e0def4 #26233a   #26233a
client.urgent           #eb6f92 #eb6f92 #191724 #eb6f92   #eb6f92
EOF

# Configure Zsh
echo "🐚 Configuring Zsh..."
cat > ~/.zshrc << 'EOF'
# ThePrimeagen's Zsh Configuration

# Path to oh-my-zsh installation
export ZSH="$HOME/.oh-my-zsh"

# Set theme
ZSH_THEME="powerlevel10k/powerlevel10k"

# Plugins
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)

source $ZSH/oh-my-zsh.sh

# Custom aliases
alias vim="nvim"
alias vi="nvim"
alias ll="ls -alF"
alias la="ls -A"
alias l="ls -CF"
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias grep="grep --color=auto"
alias fgrep="fgrep --color=auto"
alias egrep="egrep --color=auto"

# Custom functions
function mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Add local bin to PATH
export PATH="$HOME/.local/bin:$PATH"

# FZF configuration
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

# Tmux sessionizer binding
bindkey -s '^f' 'tmux-sessionizer\n'
EOF

# Update PATH in current session
export PATH="$HOME/.local/bin:$PATH"

# Set Zsh as default shell
echo "🐚 Setting Zsh as default shell..."
chsh -s $(which zsh)

# Final verification
echo "🔍 Verifying installation..."
echo "Neovim version:"
/usr/local/bin/nvim --version | head -1
echo "Tmux version:"
tmux -V
echo "Zsh version:"
zsh --version
echo "Git version:"
git --version

echo "✅ CLEAN INSTALLATION COMPLETE!"
echo ""
echo "🎉 ThePrimeagen's setup has been cleanly installed!"
echo ""
echo "📋 Next steps:"
echo "1. Reboot your system: sudo reboot"
echo "2. Log in and start i3 window manager from your display manager"
echo "3. Open Alacritty terminal (Super+Enter in i3)"
echo "4. Run 'nvim' and execute ':PackerSync' to install Neovim plugins"
echo "5. Configure PowerLevel10k by running 'p10k configure'"
echo "6. Create your project directories in ~/work and ~/personal"
echo ""
echo "🔑 Key bindings:"
echo "- Super+Enter: Open terminal"
echo "- Super+d: Application launcher"
echo "- Ctrl+f (in terminal): tmux-sessionizer"
echo "- Space (in Neovim): Leader key"
echo "- Leader+pf: Find files (Telescope)"
echo "- Leader+a: Add file to Harpoon"
echo "- Ctrl+e: Harpoon quick menu"
echo ""
echo "🚀 Happy coding like ThePrimeagen!"
EOF

chmod +x install-primeagen-setup-ubuntu-clean.sh
