#!/bin/bash
# Check dependencies for the YouTube transcript skill.

MISSING=0

if ! command -v curl &>/dev/null; then
    echo "ERROR: curl is not installed"
    echo "  macOS:         brew install curl"
    echo "  Ubuntu/Debian: sudo apt-get install curl"
    echo "  Fedora:        sudo dnf install curl"
    MISSING=1
fi

if ! command -v jq &>/dev/null; then
    echo "ERROR: jq is not installed"
    echo "  macOS:         brew install jq"
    echo "  Ubuntu/Debian: sudo apt-get install jq"
    echo "  Fedora:        sudo dnf install jq"
    MISSING=1
fi

if (( MISSING )); then
    exit 1
fi

echo "All dependencies available"
echo "  - curl: $(curl --version | head -1)"
echo "  - jq:   $(jq --version)"
