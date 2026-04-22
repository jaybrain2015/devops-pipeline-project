#!/bin/bash

# ============================================
# Production Health Check Script
# Used before every deployment
# Author: John Jonah
# ============================================

# ── Colors ──────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ── Config ───────────────────────────────────
MIN_DISK_SPACE=10
MIN_MEMORY_MB=200
LOG_FILE=~/devops-project/logs/health-check.log
PASS=0
FAIL=0
WARN=0

# ── Functions ────────────────────────────────
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> $LOG_FILE
}

pass() {
    echo -e "  ${GREEN}✅ PASS${NC} $1"
    log "PASS: $1"
    PASS=$((PASS + 1))
}

fail() {
    echo -e "  ${RED}❌ FAIL${NC} $1"
    log "FAIL: $1"
    FAIL=$((FAIL + 1))
}

warn() {
    echo -e "  ${YELLOW}⚠️  WARN${NC} $1"
    log "WARN: $1"
    WARN=$((WARN + 1))
}

section() {
    echo ""
    echo -e "${BLUE}▶ $1${NC}"
    log "--- $1 ---"
}

# ── Start ────────────────────────────────────
clear
echo "============================================"
echo "   🔍 DevOps Health Check"
echo "   $(date)"
echo "   Host: $(hostname)"
echo "   User: $(whoami)"
echo "============================================"
log "Health check started by $(whoami)"

# ── 1. Disk Space ────────────────────────────
section "Disk Space"
DISK_USED=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
DISK_FREE=$((100 - DISK_USED))

if [ $DISK_FREE -gt $MIN_DISK_SPACE ]; then
    pass "Disk space OK — ${DISK_FREE}% free (${DISK_USED}% used)"
else
    fail "Low disk space — only ${DISK_FREE}% free"
fi

# ── 2. Memory ────────────────────────────────
section "Memory"
FREE_MB=$(free -m | grep Mem | awk '{print $4}')
TOTAL_MB=$(free -m | grep Mem | awk '{print $2}')
USED_MB=$((TOTAL_MB - FREE_MB))

if [ $FREE_MB -gt $MIN_MEMORY_MB ]; then
    pass "Memory OK — ${FREE_MB}MB free of ${TOTAL_MB}MB total"
else
    warn "Low memory — only ${FREE_MB}MB free"
fi

# ── 3. CPU Load ──────────────────────────────
section "CPU"
CPU_CORES=$(nproc)
LOAD=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | tr -d ',')
pass "CPU load: $LOAD (${CPU_CORES} cores available)"

# ── 4. Critical Services ─────────────────────
section "Services"
SERVICES=("nginx" "mysql" "docker")

for SERVICE in "${SERVICES[@]}"; do
    if systemctl is-active --quiet $SERVICE 2>/dev/null; then
        pass "$SERVICE is running"
    elif command -v $SERVICE &>/dev/null; then
        warn "$SERVICE installed but not running as service"
    else
        fail "$SERVICE not found"
    fi
done

# ── 5. Critical Ports ────────────────────────
section "Ports"
declare -A PORTS
PORTS=([80]="Nginx" [3306]="MySQL" [8080]="Jenkins" [5432]="Postgres")

for PORT in "${!PORTS[@]}"; do
    SERVICE_NAME=${PORTS[$PORT]}
    if ss -tulpn | grep -q ":$PORT "; then
        pass "Port $PORT ($SERVICE_NAME) is active"
    else
        warn "Port $PORT ($SERVICE_NAME) not listening"
    fi
done

# ── 6. Docker ────────────────────────────────
section "Docker"
if command -v docker &>/dev/null; then
    if docker info &>/dev/null 2>&1; then
        CONTAINERS=$(docker ps --format '{{.Names}}' | wc -l)
        pass "Docker running — $CONTAINERS container(s) active"
        if [ $CONTAINERS -gt 0 ]; then
            echo "     Running containers:"
            docker ps --format "     • {{.Names}} ({{.Status}})"
        fi
    else
        fail "Docker installed but daemon not running"
    fi
else
    fail "Docker not installed"
fi

# ── 7. Internet Connectivity ─────────────────
section "Connectivity"
if ping -c 1 -W 3 google.com &>/dev/null; then
    pass "Internet connectivity OK"
else
    fail "No internet connectivity"
fi

if curl -s --max-time 5 https://hub.docker.com &>/dev/null; then
    pass "DockerHub reachable"
else
    warn "DockerHub not reachable"
fi

# ── 8. Project Structure ─────────────────────
section "Project Structure"
DIRS=(
    "~/devops-project/scripts"
    "~/devops-project/config"
    "~/devops-project/logs"
    "~/devops-project/app"
)

for DIR in "${DIRS[@]}"; do
    EXPANDED=$(eval echo $DIR)
    if [ -d "$EXPANDED" ]; then
        pass "Directory exists: $DIR"
    else
        fail "Missing directory: $DIR"
    fi
done

# ── 9. Git ───────────────────────────────────
section "Git"
if command -v git &>/dev/null; then
    GIT_VERSION=$(git --version | awk '{print $3}')
    pass "Git $GIT_VERSION installed"
    
    cd ~/devops-project
    if git rev-parse --git-dir &>/dev/null 2>&1; then
        BRANCH=$(git branch --show-current 2>/dev/null)
        pass "Git repo initialized — branch: $BRANCH"
    else
        warn "devops-project not a git repo yet"
    fi
else
    fail "Git not installed"
fi

# ── Final Summary ────────────────────────────
echo ""
echo "============================================"
echo -e "   ${GREEN}✅ Passed: $PASS${NC}"
echo -e "   ${YELLOW}⚠️  Warnings: $WARN${NC}"
echo -e "   ${RED}❌ Failed: $FAIL${NC}"
echo "============================================"
log "Health check complete — PASS:$PASS WARN:$WARN FAIL:$FAIL"

if [ $FAIL -eq 0 ]; then
    echo -e "   ${GREEN}🚀 READY TO DEPLOY${NC}"
    log "Result: READY"
    exit 0
else
    echo -e "   ${RED}🛑 NOT READY — Fix failures first${NC}"
    log "Result: NOT READY"
    exit 1
fi
echo "============================================"
