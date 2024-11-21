# HOW TO GENERATE BACKEND USING HAMMER

## REQUIREMENTS

Before you begin, make sure you have the following tools installed:

### Shell

- Bash (Linux, macOS, or Git Bash on Windows)
- `curl` command for interacting with the server

### Docker

- Docker 
- Ensure that your Docker daemon is running and properly configured

## USING JSON

To use the Hammer tool with JSON configuration, no option needed as json is the default format:

```bash
./hammer_out.sh
```

## USING YAML

To use the Hammer tool with YAML configuration:

```bash
./hammer_out.sh --format=yaml
```

The script will generate the backend files based on the selected format. By default, the format is set to JSON, but you can change it to YAML using the `--format` option.

## STARTING THE SERVER

Once the backend generation is complete, you can start the server by running the following command:
No option needed to start the server because it is the default action.
```bash
./hammer_out.sh
```

This will start the backend server within a Docker container, and your application will be available at `http://localhost:<your-port>`.

### Check if the server is running

If you kept default config and models files you can test the server by running the following curls.

- **Add a user** (POST request):

  ```bash
  curl -X POST http://localhost:3000/user   -H "Content-Type: application/json"   -d '{
    "name": "John Doe",
    "email": "john.doe@example.com"
  }'
  ```

- **Get all users** (GET request):

  ```bash
  curl -X GET http://localhost:3000/user
  ```

These commands will allow you to interact with your backend service and verify that the server is responding correctly.

## ZIPPING THE PROJECT

After generating the backend files, you can choose to zip the project directory with the following command:

```bash
./hammer_out.sh --action=zip
```

This will compress the generated files into a `.zip` file located in the `output_path` directory.

## NOTES

- The script supports both `json` and `yaml` formats. Make sure that the configuration and models files are in the same format (both JSON or both YAML).
- If you keep the same models, you can reuse them for subsequent generations.
- If the project with the same name already exists, the script will not overwrite it.
