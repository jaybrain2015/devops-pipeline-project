#!/bin/bash

# ── Colors ──────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ── Functions ───────────────────────────────

# Log function - reuse everywhere
log_info() {
    echo -e "${BLUE}[INFO]${NC} $(date '+%H:%M:%S') - $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $(date '+%H:%M:%S') - $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $(date '+%H:%M:%S') - $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $(date '+%H:%M:%S') - $1"
}

# Check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Check if a port is in use
port_in_use() {
    ss -tulpn | grep ":$1 " &> /dev/null
}

# Create directory safely
create_dir() {
    if [ ! -d "$1" ]; then
        mkdir -p "$1"
        log_success "Created directory: $1"
    else
        log_info "Directory already exists: $1"
    fi
}

# ── Main Script ─────────────────────────────
log_info "Starting environment check..."
echo ""

# Check tools
TOOLS=("docker" "git" "curl" "nginx")
for TOOL in "${TOOLS[@]}"; do
    if command_exists $TOOL; then
        log_success "$TOOL is installed"
    else
        log_warning "$TOOL is NOT installed"
    fi
done

echo ""

# Check ports
log_info "Checking critical ports..."
PORTS=("80" "3306" "8080" "3000")
for PORT in "${PORTS[@]}"; do
    if port_in_use $PORT; then
        log_success "Port $PORT is active"
    else
        log_warning "Port $PORT is not in use"
    fi
done

echo ""

# Create directories
log_info "Ensuring project structure..."
create_dir ~/devops-project/scripts
create_dir ~/devops-project/config
create_dir ~/devops-project/logs
create_dir ~/devops-project/app

echo ""
log_success "Environment check complete!"
