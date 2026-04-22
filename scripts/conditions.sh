#!/bin/bash


ENVIRONMENT=$1


if [ -z "$ENVIRONMENT" ]; then
	echo "X Error: No environment specified"
	echo "Usage: ./conditons.sh [production|staging|dev]"
	exit 1
fi


if [ "$ENVIRONMENT" == "production" ]; then
	echo "⚠️  WARNING: Deploying to PRODUCTION"
	echo "Double check everything before proceeding"
elif [ "$ENVIRONMENT" == "staging" ]; then
    echo "✅ Deploying to staging - safe to proceed"
elif [ "$ENVIRONMENT" == "dev" ]; then
    echo "✅ Deploying to dev - go ahead"
else
    echo "❌ Unknown environment: $ENVIRONMENT"
    exit 1
fi

echo ""
echo "Running pre-deployment checks..."


if [ -f ~/devops-project/config/app.conf ]; then
	echo "✅ Config file found"
else
	echo "❌ Config file missing - cannot deploy"
    exit 1
fi

if [ -d ~/devops-project/logs ]; then
    echo "✅ Logs directory exists"
else
    echo "⚠️  Creating logs directory..."
    mkdir -p ~/devops-project/logs
fi

echo ""
echo "✅ All checks passed for $ENVIRONMENT"
