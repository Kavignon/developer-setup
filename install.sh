#!/bin/bash

# Developer Setup Installation Script
# Usage: curl -fsSL https://raw.githubusercontent.com/Kavignon/developer-setup/main/install.sh | bash

set -e

echo "🚀 Starting developer environment setup..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}[SETUP]${NC} $1"
}

# Check if running in a devcontainer
if [ -n "$CODESPACES" ] || [ -n "$DEVCONTAINER" ]; then
    print_status "Detected development container environment"
    IS_CONTAINER=true
else
    IS_CONTAINER=false
fi

# Base URL for raw files
BASE_URL="https://raw.githubusercontent.com/Kavignon/developer-setup/main"

# Function to download and install a config file
install_config() {
    local file=$1
    local target=$2
    local backup=${3:-true}
    
    print_header "Installing $file..."
    
    # Create backup if file exists and backup is requested
    if [ "$backup" = true ] && [ -f "$target" ]; then
        print_warning "Backing up existing $target to ${target}.backup"
        cp "$target" "${target}.backup"
    fi
    
    # Download the file
    if curl -fsSL "$BASE_URL/$file" -o "$target"; then
        print_status "Successfully installed $file to $target"
    else
        print_error "Failed to download $file"
        return 1
    fi
}

# Function to create directories if they don't exist
ensure_dir() {
    if [ ! -d "$1" ]; then
        mkdir -p "$1"
        print_status "Created directory: $1"
    fi
}

# Main installation
main() {
    print_header "Kevin's Developer Environment Setup"
    
    # Ensure home directory configs exist
    ensure_dir "$HOME/.config"
    
    # Install Git configuration
    install_config ".gitconfig" "$HOME/.gitconfig"
    
    # Install global gitignore
    if curl -fsSL "$BASE_URL/.gitignore_global" -o "$HOME/.gitignore_global" 2>/dev/null; then
        print_status "Successfully installed global gitignore"
    else
        print_warning "Global gitignore not found, skipping..."
    fi
    
    # Install Zsh configurations
    install_config ".p10k.zsh" "$HOME/.p10k.zsh"
    
    # Install .zshrc if it exists
    if curl -fsSL "$BASE_URL/.zshrc" -o "$HOME/.zshrc" 2>/dev/null; then
        print_status "Successfully installed .zshrc"
    else
        print_warning ".zshrc not found in repo, skipping..."
    fi
    
    # Container-specific setup
    if [ "$IS_CONTAINER" = true ]; then
        print_header "Configuring for container environment..."
        
        # Source the p10k config if zsh is available
        if command -v zsh >/dev/null 2>&1; then
            if [ -f "$HOME/.zshrc" ]; then
                echo 'source ~/.p10k.zsh' >> "$HOME/.zshrc"
            fi
        fi
        
        # Set git config for container (use container-friendly settings)
        git config --global core.filemode false
        git config --global safe.directory '*'
        
        print_status "Container-specific configurations applied"
    fi
    
    # Install development tools configurations (if they exist)
    configs_to_try=(
        ".editorconfig:$HOME/.editorconfig"
        ".tool-versions:$HOME/.tool-versions"
        "vscode-settings.json:$HOME/.config/Code/User/settings.json"
    )
    
    for config in "${configs_to_try[@]}"; do
        IFS=':' read -r source target <<< "$config"
        if curl -fsSL "$BASE_URL/$source" -o "$target" 2>/dev/null; then
            print_status "Successfully installed $source"
        else
            print_warning "$source not found, skipping..."
        fi
    done
    
    print_header "Setup completed! 🎉"
    echo ""
    echo -e "${GREEN}Next steps:${NC}"
    echo "1. Restart your shell or run: source ~/.zshrc"
    echo "2. Verify git config: git config --list --global"
    echo "3. Check p10k: echo \$POWERLEVEL9K_MODE"
    echo ""
    echo -e "${BLUE}Repository:${NC} https://github.com/Kavignon/developer-setup"
}

# Run the main function
main "$@"