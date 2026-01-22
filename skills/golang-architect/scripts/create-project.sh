#!/bin/bash
set -e

# Go Symphony Project Creator
# Uses go-symphony CLI to scaffold Go backend projects
# Reference: https://github.com/Tomlord1122/go-symphony

PROJECT_NAME="${1:-}"
ADVANCED="${2:-false}"

cleanup() {
    if [ -n "$TEMP_DIR" ] && [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR"
    fi
}
trap cleanup EXIT

# Check if go-symphony is installed
check_go_symphony() {
    if ! command -v go-symphony &> /dev/null; then
        echo "go-symphony not found. Installing..." >&2
        go install github.com/Tomlord1122/go-symphony@latest
        if [ $? -ne 0 ]; then
            echo '{"success": false, "error": "Failed to install go-symphony"}'
            exit 1
        fi
        echo "go-symphony installed successfully" >&2
    fi
}

show_usage() {
    cat << 'EOF'
Usage: create-project.sh <project-name> [advanced]

Arguments:
  project-name  Name of the project to create (required)
  advanced      Set to 'true' for advanced features prompt (optional)

Examples:
  create-project.sh my-api
  create-project.sh my-api true

Generated Structure:
  project/
  ├── cmd/api/main.go         # Entry point
  ├── internal/
  │   ├── server/             # Gin server and routes
  │   ├── database/           # Database service layer
  │   └── db_sqlc/            # SQLC generated code
  ├── sqlc/
  │   ├── migrations/         # SQL schema files
  │   └── queries/            # SQL query files
  ├── Makefile                # Build commands
  └── docker-compose.yml      # Database containers
EOF
}

# Main execution
if [ -z "$PROJECT_NAME" ]; then
    show_usage
    echo '{"success": false, "error": "Project name is required"}'
    exit 1
fi

echo "Checking go-symphony installation..." >&2
check_go_symphony

echo "Creating project: $PROJECT_NAME" >&2

if [ "$ADVANCED" = "true" ]; then
    echo "Running in advanced mode..." >&2
    go-symphony create -n "$PROJECT_NAME" -a
else
    go-symphony create -n "$PROJECT_NAME"
fi

if [ $? -eq 0 ]; then
    echo '{"success": true, "project": "'"$PROJECT_NAME"'", "message": "Project created successfully"}'
else
    echo '{"success": false, "error": "Failed to create project"}'
    exit 1
fi
