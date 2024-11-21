#!/usr/bin/env bash

# Default parameters
format="json"
action="start"
output_path="./generated"
mold_path="./mold"
port=""
project_name=""

# Helper function to show usage
show_help() {
  echo "Usage: $0 [options]"
  echo "Options:"
  echo "  --format [json|yaml]         Format of configuration and model files (default: json)"
  echo "  --action [start|zip]         Action to perform after generation (default: start)"
  echo "  --help                       Show this help message"
  exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --format)
      format="$2"
      shift 2
      ;;
    --action)
      action="$2"
      shift 2
      ;;
    --help)
      show_help
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      show_help
      exit 1
      ;;
  esac
done

config_path="./config.$format"
models_path="./models.$format"

# Validate format
if [[ "$format" != "json" && "$format" != "yaml" ]]; then
  echo "Error: Unsupported format. Use 'json' or 'yaml'."
  exit 1
fi

echo "Starting generation with format: $format"

# Check if required files exist
if [[ ! -f "$config_path" ]]; then
  echo "Error: Config file not found at $config_path"
  exit 1
fi

if [[ ! -f "$models_path" ]]; then
  echo "Error: Models file not found at $models_path"
  exit 1
fi

if [[ ! -d "$mold_path" ]]; then
  echo "Error: Mold directory not found at $mold_path"
  exit 1
fi

# Validate formats
config_ext="${config_path##*.}"
models_ext="${models_path##*.}"

if [[ "$config_ext" != "$models_ext" ]]; then
  echo "Error: Config and Models files must use the same format (both JSON or both YAML)."
  exit 1
fi

format="$config_ext"

# Extract project details from config
if [[ "$format" == "json" ]]; then
  project_name=$(grep -oP '"project_name"\s*:\s*"\K[^"]+' "$config_path")
  port=$(grep -oP '"project_port"\s*:\s*\K\d+' "$config_path")
else
  project_name=$(grep -E '^project_name:' "$config_path" | awk -F': ' '{print $2}' | tr -d '"')
  port=$(grep -E '^project_port:' "$config_path" | awk -F': ' '{print $2}')
fi

# Ensure project_name and port are valid
if [[ -z "$port" || -z "$project_name" ]]; then
  echo "Error: Missing 'project_port' or 'project_name' in config file."
  exit 1
fi

# Check if port is used and exit if true
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
  # For Windows, use netstat with findstr to check for port usage
  echo "Checking if port $port is in use on Windows..."
  netstat -ano | findstr ":$port"  # Show the result of netstat for debugging
  if netstat -ano | findstr ":$port" > /dev/null; then
    echo "Error: Port $port is already in use."
    exit 1
  fi
else
  # For Unix-like systems, use lsof to check if the port is being used
  echo "Checking if port $port is in use on Unix-like system..."
  lsof -Pi :$port -sTCP:LISTEN -t  # Show the result of lsof for debugging
  if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null; then
    echo "Error: Port $port is already in use."
    exit 1
  fi
fi


# Check if Docker is installed
if ! command -v docker &> /dev/null; then
  echo "Error: Docker is not installed."
  exit 1
fi

# Check if project_name is already generated
if [[ -d "$output_path/$project_name" ]]; then
  echo "Error: Project with name $project_name already exists in output directory."
  exit 1
fi

# Start Docker container
container_id=$(docker run -d --name hammer_worker python:3.9-slim bash -c "mkdir /app && sleep infinity")

if [[ -z "$container_id" ]]; then
  echo "Error: Failed to start Docker container."
  exit 1
fi

# Copy files into the container
docker cp "$config_path" "$container_id:/app/config.$format"
docker cp "$models_path" "$container_id:/app/models.$format"
docker cp "$mold_path" "$container_id:/app/mold"
docker cp "hammer_out_from_$format.py" "$container_id:/app/hammer_out_from_$format.py"


# Check if running on Windows (Git Bash)
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
  winpty_prefix="winpty"
else
  winpty_prefix=""
fi

if [[ "$format" == "yaml" ]]; then
  echo "Installing pyyaml and running Hammer script for format: $format"
  $winpty_prefix docker exec -it "$container_id" bash -c "cd /app && pip install pyyaml && python hammer_out_from_$format.py"
else
  echo "Running Hammer script for format: $format"
  $winpty_prefix docker exec -it "$container_id" bash -c "cd /app && python hammer_out_from_$format.py"
fi

# Copy generated files back to host
mkdir -p "$output_path"
docker cp "$container_id:/app/$project_name" "$output_path/$project_name"

# Verify generated files
if [[ ! -d "$output_path/$project_name/" || -z "$(ls -A "$output_path/$project_name/")" ]]; then
  echo "Error: Generation failed. No files in output directory."
  docker stop "$container_id"
  docker rm "$container_id"
  exit 1
fi

# Perform post-generation actions
if [[ "$action" == "zip" ]]; then
  # Check if the operating system is Windows
  if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    # If on Windows, use PowerShell's Compress-Archive
    echo "Running on Windows, using PowerShell to zip."
    powershell Compress-Archive -Path "$output_path/$project_name" -DestinationPath "$output_path/$project_name.zip"
  else
    # If on Linux or macOS, use the `zip` command
    echo "Running on Linux/macOS, using zip."
    zip -r "$output_path/$project_name.zip" "$output_path/$project_name"
  fi

elif [[ "$action" == "start" ]]; then
  # Start the Docker container with a Node.js image
  docker run -d --name "$project_name" -v "$(pwd):/app" -p "$port:$port" node:16 bash -c "sleep infinity"

  container_id=$(docker ps -q -f name="$project_name")
  if [[ -z "$container_id" ]]; then
    echo "Error: Failed to start Docker container."
    exit 1
  fi

  # Copy all the necessary files from the generated project to the container's /app directory
  docker cp "$output_path/$project_name/." "$container_id:/app"

  # Run npm install and other necessary commands inside the Docker container
  $winpty_prefix docker exec -d "$container_id" bash -c "cd /app && npm install && npm run prestart && npm run preprisma && npm run prisma && npm start"

  # Wait for the server to start
  echo "Waiting for server to start..."
  sleep 30

  # Check if the server is up and running
  curl "http://localhost:$port"
  if [[ $? -ne 0 ]]; then
    echo "No response yet, trying one more time."
    sleep 30
    curl "http://localhost:$port"
    if [[ $? -ne 0 ]]; then
      echo "Error: Failed to start project."
      rm -rf "$output_path/$project_name"
      docker stop "$container_id"
      docker rm "$container_id"
      docker stop hammer_worker
      docker rm hammer_worker
      exit 1
    fi
  fi
fi

# Clean up Docker container after use
docker stop hammer_worker
docker rm hammer_worker

echo "Success! Files generated and action completed."
exit 0