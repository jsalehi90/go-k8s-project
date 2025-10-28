#!/bin/bash
set -e

echo "Running tests..."

go run main.go &

sleep 5

response=$(curl -s http://localhost:80)
if [[ "$response" == *"Hello from Go!"* ]]; then
    echo "✅ Test passed!"
else
    echo "❌ Test failed!"
    exit 1
fi

pkill -f "go run"

echo "Tests completed successfully."