#!/usr/bin/env bash

# Function to validate the port number
validate_port() {
  local port=$1
  # Check if the port is a valid number between 1 and 65535
  if [[ ! $port =~ ^[0-9]+$ ]] || ((port < 1 || port > 65535)); then
    echo "Error: Port must be a number between 1 and 65535."
    return 1
  fi

  # Check if the port is in use using netstat
  if netstat -an | grep ":$port " | grep -q LISTEN; then
    echo "Error: Port $port is already in use."
    return 1
  fi

  return 0
}

# Function to validate the project name
validate_project_name() {
  local name=$1
  # Check if the project directory already exists
  if [ -d "$name" ]; then
    echo "Error: A project with the name '$name' already exists."
    return 1
  fi
  return 0
}

# Function to display usage
usage() {
  echo "Usage: $0 [-name=project_name] [-port=port]"
  exit 1
}

# Function to check if required files exist
check_files_exist() {
  if [ ! -f "generate_openapi_yaml.py" ]; then
    echo "Error: generate_openapi_yaml.py does not exist."
    exit 1
  fi

  if [ ! -f "mold.yaml" ]; then
    echo "Error: mold.yaml does not exist."
    exit 1
  fi
}

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -name=* )
      PROJECT_NAME="${1#*=}"
      shift
      ;;
    -port=* )
      PORT="${1#*=}"
      shift
      ;;
    * )
      usage
      ;;
  esac
done

# If running in command-line mode (arguments provided), validate them
if [ -n "$PROJECT_NAME" ]; then
  validate_project_name "$PROJECT_NAME" || exit 1
fi

if [ -n "$PORT" ]; then
  validate_port "$PORT" || exit 1
fi

# If no arguments are passed (interactive mode), ask for the values
if [ -z "$PROJECT_NAME" ]; then
  while true; do
    echo "Enter the name of your project:"
    read PROJECT_NAME
    if [ -z "$PROJECT_NAME" ]; then
      echo "Project name cannot be empty."
    elif validate_project_name "$PROJECT_NAME"; then
      break
    fi
  done
fi

# If no port is provided, ask for it interactively
if [ -z "$PORT" ]; then
  while true; do
    echo "Enter the port number for your backend (1-65535):"
    read PORT
    if validate_port "$PORT"; then
      break
    fi
  done
fi

# Check if required files exist (generate_openapi_yaml.py and mold.yaml)
check_files_exist

# Run the Python script to generate OpenAPI YAML
pip install pyyaml --trusted-host pypi.org --trusted-host pypi.python.org --trusted-host=files.pythonhosted.org
python generate_openapi_yaml.py

# Run OpenAPI codegen command to generate code based on the generated OpenAPI spec
openapi-generator-cli generate -i openapi.yaml -g nodejs-express-server -o ./$PROJECT_NAME

echo "Project setup complete and code generated!"
