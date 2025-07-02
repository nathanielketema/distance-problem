#!/bin/bash

# ThePrimeagen Setup Script for Ubuntu (Updated with correct repos)
# This script installs and configures ThePrimeagen's actual setup

set -e

echo "🚀 Installing ThePrimeagen's Setup for Ubuntu (Updated)"
echo "⚠️  WARNING: This will clean existing configurations in 10 seconds..."
echo "Press Ctrl+C to cancel"
sleep 10

# Cleanup function
cleanup_existing() {
    echo "🧹 Cleaning existing configurations..."
    
    # Kill tmux sessions
    tmux kill-server 2>/dev/null || true
    
    # Remove config directories
    rm -rf ~/.config/nvim
    rm -rf ~/.local/share/nvim
    rm -rf ~/.local/state/nvim
    rm -rf ~/.config/tmux
    rm -rf ~/.config/alacritty
    rm -rf ~/.config/i3
    rm -rf ~/.oh-my-zsh
    rm -rf ~/.tmux
    
    # Remove fonts
    rm -rf ~/.local/share/fonts/NerdFonts
    
    echo "✅ Cleanup completed"
}

# Update system
update_system() {
    echo "📦 Updating system packages..."
    sudo apt update && sudo apt upgrade -y
}

# Install essential packages
install_packages() {
    echo "📦 Installing essential packages..."
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
        zsh \
        tmux \
        fzf \
        ripgrep \
        fd-find \
        tree \
        htop \
        nodejs \
        npm \
        python3 \
        python3-pip \
        i3 \
        i3status \
        i3lock \
        dmenu \
        xclip
}

# Install Alacritty
install_alacritty() {
    echo "🖥️  Installing Alacritty..."
    sudo add-apt-repository ppa:aslatter/ppa -y
    sudo apt update
    sudo apt install -y alacritty
}

# Install Neovim (latest stable)
install_neovim() {
    echo "📝 Installing Neovim..."
    wget -O /tmp/nvim-linux-x86_64.tar.gz https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
    sudo tar -xzf /tmp/nvim-linux-x86_64.tar.gz -C /opt/
    sudo ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim
    
    # Install Python support
    pip3 install --user pynvim
}

# Install Oh My Zsh and plugins
install_zsh() {
    echo "🐚 Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    
    # Install zsh plugins
    git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
    git clone https://github.com/zsh-users/zsh-syntax-highlighting ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
    
    # Install Powerlevel10k theme
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.oh-my-zsh/custom/themes/powerlevel10k
}

# Install Nerd Fonts
install_fonts() {
    echo "🔤 Installing Nerd Fonts..."
    mkdir -p ~/.local/share/fonts/NerdFonts
    cd ~/.local/share/fonts/NerdFonts
    
    # Download JetBrains Mono Nerd Font
    wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/JetBrainsMono.zip
    unzip JetBrainsMono.zip
    rm JetBrainsMono.zip
    
    # Refresh font cache
    fc-cache -fv
}

# Setup ThePrimeagen's Neovim config
setup_neovim_config() {
    echo "📝 Setting up ThePrimeagen's Neovim configuration..."
    
    # Clone his current init.lua config
    git clone https://github.com/ThePrimeagen/init.lua.git ~/.config/nvim
    
    # Install Packer (plugin manager)
    git clone --depth 1 https://github.com/wbthomason/packer.nvim \
        ~/.local/share/nvim/site/pack/packer/start/packer.nvim
}

# Setup tmux configuration
setup_tmux() {
    echo "🖥️  Setting up tmux configuration..."
    
    mkdir -p ~/.config/tmux
    
    # Create tmux config based on ThePrimeagen's setup
    cat > ~/.config/tmux/tmux.conf << 'EOF'
# ThePrimeagen's tmux configuration
set-option -sa terminal-overrides ",xterm*:Tc"
set -g mouse on

# Set prefix
unbind C-b
set -g prefix C-a
bind C-a send-prefix

# Shift Alt vim keys to switch windows
bind -n M-H previous-window
bind -n M-L next-window

# Start windows and panes at 1, not 0
set -g base-index 1
set -g pane-base-index 1
set-window-option -g pane-base-index 1
set-option -g renumber-windows on

# Use Alt-arrow keys without prefix key to switch panes
bind -n M-Left select-pane -L
bind -n M-Right select-pane -R
bind -n M-Up select-pane -U
bind -n M-Down select-pane -D

# Shift arrow to switch windows
bind -n S-Left  previous-window
bind -n S-Right next-window

# Bind tmux-sessionizer
bind-key -r f run-shell "tmux neww ~/.local/bin/tmux-sessionizer"

# Set vi-mode
set-window-option -g mode-keys vi

# Keybindings for copy-paste
bind-key -T copy-mode-vi v send-keys -X begin-selection
bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle
bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel

# Open panes in current directory
bind '"' split-window -v -c "#{pane_current_path}"
bind % split-window -h -c "#{pane_current_path}"
EOF

    # Create symlink for tmux to find config
    ln -sf ~/.config/tmux/tmux.conf ~/.tmux.conf
}

# Setup tmux-sessionizer script
setup_tmux_sessionizer() {
    echo "🔧 Setting up tmux-sessionizer..."
    
    mkdir -p ~/.local/bin
    
    # Create tmux-sessionizer script
    cat > ~/.local/bin/tmux-sessionizer << 'EOF'
#!/usr/bin/env bash

if [[ $# -eq 1 ]]; then
    selected=$1
else
    selected=$(find ~/work ~/projects ~/ ~/.config -mindepth 1 -maxdepth 1 -type d | fzf)
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
    
    # Add to PATH if not already there
    if ! echo $PATH | grep -q "$HOME/.local/bin"; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
    fi
}

# Setup Alacritty configuration
setup_alacritty() {
    echo "🖥️  Setting up Alacritty configuration..."
    
    mkdir -p ~/.config/alacritty
    
    cat > ~/.config/alacritty/alacritty.yml << 'EOF'
# ThePrimeagen's Alacritty configuration
window:
  opacity: 0.95
  padding:
    x: 10
    y: 10

font:
  normal:
    family: "JetBrainsMono Nerd Font"
    style: Regular
  bold:
    family: "JetBrainsMono Nerd Font"
    style: Bold
  italic:
    family: "JetBrainsMono Nerd Font"
    style: Italic
  size: 14.0

colors:
  primary:
    background: '#1a1b26'
    foreground: '#c0caf5'
  normal:
    black:   '#15161e'
    red:     '#f7768e'
    green:   '#9ece6a'
    yellow:  '#e0af68'
    blue:    '#7aa2f7'
    magenta: '#bb9af7'
    cyan:    '#7dcfff'
    white:   '#a9b1d6'
  bright:
    black:   '#414868'
    red:     '#f7768e'
    green:   '#9ece6a'
    yellow:  '#e0af68'
    blue:    '#7aa2f7'
    magenta: '#bb9af7'
    cyan:    '#7dcfff'
    white:   '#c0caf5'

key_bindings:
  - { key: F, mods: Control, action: SearchForward }
  - { key: B, mods: Control, action: SearchBackward }
EOF
}

# Setup i3 window manager
setup_i3() {
    echo "🪟 Setting up i3 window manager..."
    
    mkdir -p ~/.config/i3
    
    cat > ~/.config/i3/config << 'EOF'
# ThePrimeagen-inspired i3 configuration
set $mod Mod4

# Font for window titles
font pango:JetBrainsMono Nerd Font 10

# Use Mouse+$mod to drag floating windows
floating_modifier $mod

# Start a terminal
bindsym $mod+Return exec alacritty

# Kill focused window
bindsym $mod+Shift+q kill

# Start dmenu
bindsym $mod+d exec dmenu_run

# Change focus
bindsym $mod+h focus left
bindsym $mod+j focus down
bindsym $mod+k focus up
bindsym $mod+l focus right

# Move focused window
bindsym $mod+Shift+h move left
bindsym $mod+Shift+j move down
bindsym $mod+Shift+k move up
bindsym $mod+Shift+l move right

# Split in horizontal orientation
bindsym $mod+b split h

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
    bindsym h resize shrink width 10 px or 10 ppt
    bindsym j resize grow height 10 px or 10 ppt
    bindsym k resize shrink height 10 px or 10 ppt
    bindsym l resize grow width 10 px or 10 ppt
    
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
EOF
}

# Setup Zsh configuration
setup_zsh_config() {
    echo "🐚 Setting up Zsh configuration..."
    
    cat > ~/.zshrc << 'EOF'
# ThePrimeagen-inspired Zsh configuration
export ZSH="$HOME/.oh-my-zsh"

# Theme
ZSH_THEME="powerlevel10k/powerlevel10k"

# Plugins
plugins=(
    git
    zsh-autosuggestions
    zsh-syntax-highlighting
    fzf
)

source $ZSH/oh-my-zsh.sh

# User configuration
export PATH="$HOME/.local/bin:$PATH"
export EDITOR="nvim"
export VISUAL="nvim"

# Aliases
alias vim="nvim"
alias vi="nvim"
alias ll="ls -alF"
alias la="ls -A"
alias l="ls -CF"
alias ..="cd .."
alias ...="cd ../.."
alias grep="grep --color=auto"

# FZF configuration
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

# Tmux sessionizer binding
bindkey -s ^f "tmux-sessionizer\n"
EOF

    # Change default shell to zsh
    chsh -s $(which zsh)
}

# Create project directories
setup_directories() {
    echo "📁 Creating project directories..."
    mkdir -p ~/work
    mkdir -p ~/projects
    mkdir -p ~/.config
}

# Verification function
verify_installation() {
    echo "🔍 Verifying installation..."
    
    command -v nvim >/dev/null 2>&1 && echo "✅ Neovim installed" || echo "❌ Neovim not found"
    command -v tmux >/dev/null 2>&1 && echo "✅ Tmux installed" || echo "❌ Tmux not found"
    command -v alacritty >/dev/null 2>&1 && echo "✅ Alacritty installed" || echo "❌ Alacritty not found"
    command -v fzf >/dev/null 2>&1 && echo "✅ FZF installed" || echo "❌ FZF not found"
    command -v rg >/dev/null 2>&1 && echo "✅ Ripgrep installed" || echo "❌ Ripgrep not found"
    [ -f ~/.local/bin/tmux-sessionizer ] && echo "✅ tmux-sessionizer installed" || echo "❌ tmux-sessionizer not found"
    [ -d ~/.config/nvim ] && echo "✅ Neovim config found" || echo "❌ Neovim config not found"
}

# Main execution
main() {
    cleanup_existing
    update_system
    install_packages
    install_alacritty
    install_neovim
    install_zsh
    install_fonts
    setup_neovim_config
    setup_tmux
    setup_tmux_sessionizer
    setup_alacritty
    setup_i3
    setup_zsh_config
    setup_directories
    verify_installation
    
    echo "🎉 Installation completed!"
    echo ""
    echo "📋 Next steps:"
    echo "1. Reboot your system to ensure all changes take effect"
    echo "2. Log into i3 window manager"
    echo "3. Open Neovim and run :PackerSync to install plugins"
    echo "4. Run 'p10k configure' to set up Powerlevel10k theme"
    echo "5. Create some projects in ~/work or ~/projects for tmux-sessionizer"
    echo ""
    echo "🔑 Key bindings:"
    echo "- Ctrl+f: tmux-sessionizer (in terminal)"
    echo "- <leader>pf: Find files in Neovim (Space+pf)"
    echo "- <leader>ps: Grep string in Neovim (Space+ps)"
    echo "- Ctrl+a: tmux prefix"
    echo "- Super+Return: Open terminal in i3"
    echo ""
    echo "🎯 ThePrimeagen's workflow is now ready!"
}

# Run main function
main
