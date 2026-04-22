#!/bin/bash

APP_NAME="devops-app"
VERSION="1.0.0"
ENVIRONMENT="production"

CURRENT_USER=$(whoami)
CURRENT_DATE=$(date +%Y-%m-%d)
CURRENT_TIME=$(date +%H:%M:%S)

echo "APP: $APP_NAME"
echo "version: $VERSION"
echo "Environment: $ENVIRONMENT"
echo "Deployed by: $CURRENT_USER"
echo "Date: $CURRENT_DATE"
echo "Time: $CURRENT_TIME"


MAJOR=1
MINOR=2
PATCH=3
FULL_VERSION="$MAJOR.$MINOR.$PATCH"
echo " full version: $FULL_VERSION"

