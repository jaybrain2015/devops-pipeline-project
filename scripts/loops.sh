#!/bin/bash

echo "=== Checking Servers ==="
SERVERS=("web-01" "web-02" "web-03" "db-01")

for SERVER in "${SERVERS[@]}"; do
	  echo "Checking $SERVER..."
          sleep 0.5
          echo "✅ $SERVER is healthy"
       done

echo ""

echo "=== Creating Log Files ==="
for i in  {1..3}; do
	LOGFILE=~/devops-project/logs/app-$(date +%Y-%m-%d) -$i.log
	touch $LOGFILE
	echo "Log entry created at $(date)" > $LOGFILE
	echo "Created: $LOGFILE"
done

echo ""

# ── While loop ──────────────────────────────
echo "=== Waiting for service (simulated) ==="
ATTEMPTS=0
MAX_ATTEMPTS=5

while [ $ATTEMPTS -lt $MAX_ATTEMPTS ]; do
    ATTEMPTS=$((ATTEMPTS + 1))
    echo "Attempt $ATTEMPTS of $MAX_ATTEMPTS..."
    sleep 1
    
    # Simulate success on attempt 3
    if [ $ATTEMPTS -eq 3 ]; then
        echo "✅ Service is ready!"
        break
    fi
done

if [ $ATTEMPTS -eq $MAX_ATTEMPTS ]; then
    echo "❌ Service failed to start after $MAX_ATTEMPTS attempts"
fi

echo ""

# ── Loop through files ──────────────────────
echo "=== Reading Config Files ==="
for FILE in ~/devops-project/config/*; do
    echo "Found config: $FILE"
    echo "Contents:"
    cat $FILE
    echo "---"
done

