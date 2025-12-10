#!/bin/bash

###############################################################################
# SerphunterRecon Installation Script
# Validates dependencies and sets up the environment
###############################################################################

set -e

# Color codes
RED='\033[91m'
GREEN='\033[92m'
YELLOW='\033[93m'
BLUE='\033[94m'
NC='\033[0m'

echo -e "${BLUE}"
echo "╔════════════════════════════════════════════════════╗"
echo "║     SerphunterRecon v1.0 - Installation Script     ║"
echo "╚════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Check required dependencies
echo ""
echo -e "${YELLOW}[*] Checking dependencies...${NC}"

required_tools=("bash" "curl" "grep" "sort" "uniq" "bc")
missing_tools=()

for tool in "${required_tools[@]}"; do
    if command -v "$tool" &> /dev/null; then
        version=$("$tool" --version 2>&1 | head -n1 || echo "installed")
        echo -e "${GREEN}[✓] $tool${NC} - $version"
    else
        echo -e "${RED}[✗] $tool - NOT FOUND${NC}"
        missing_tools+=("$tool")
    fi
done

if [[ ${#missing_tools[@]} -gt 0 ]]; then
    echo ""
    echo -e "${RED}[!] Missing required tools: ${missing_tools[*]}${NC}"
    echo -e "${YELLOW}[*] Please install the missing dependencies:${NC}"
    echo -e "${YELLOW}    Ubuntu/Debian: sudo apt-get install ${missing_tools[*]}${NC}"
    echo -e "${YELLOW}    macOS: brew install ${missing_tools[*]}${NC}"
    exit 1
fi

# Make scripts executable
echo ""
echo -e "${YELLOW}[*] Setting up file permissions...${NC}"

if [[ -f "serphunter.sh" ]]; then
    chmod +x serphunter.sh
    echo -e "${GREEN}[✓] Made serphunter.sh executable${NC}"
else
    echo -e "${RED}[✗] serphunter.sh not found${NC}"
    exit 1
fi

if [[ -f "install.sh" ]]; then
    chmod +x install.sh
    echo -e "${GREEN}[✓] Made install.sh executable${NC}"
fi

# Create directories
echo ""
echo -e "${YELLOW}[*] Creating directory structure...${NC}"

mkdir -p results
echo -e "${GREEN}[✓] Created results directory${NC}"

mkdir -p logs
echo -e "${GREEN}[✓] Created logs directory${NC}"

# Check config file
echo ""
echo -e "${YELLOW}[*] Checking configuration...${NC}"

if [[ -f "config.txt" ]]; then
    echo -e "${GREEN}[✓] Found config.txt${NC}"
    echo -e "${YELLOW}[*] Note: Configure API keys in config.txt for full functionality${NC}"
else
    echo -e "${YELLOW}[!] config.txt not found${NC}"
fi

# Installation complete
echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}Installation completed successfully!${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════╝${NC}"

echo ""
echo "Quick Start:"
echo "  ./serphunter.sh -d example.com"
echo ""
echo "For more options:"
echo "  ./serphunter.sh -h"
echo ""
echo "Documentation:"
echo "  See README.md for detailed usage and examples"
echo ""

exit 0
