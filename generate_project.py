import os
import shutil
import yaml

print("Creating project...")

# Read the configuration file
with open('config.yml', 'r') as config_file:
    config = yaml.load(config_file, Loader=yaml.FullLoader)
print("Configuration fetched.")

# Get project name
project_name = config['project_name']
# Get project port
project_port = config['project_port']
print(f"Project name: {project_name}")
print(f"Project port: {project_port}")

# Check if the project name already exists
if os.path.exists(project_name):
    print("Project name already exists.")
    print("Project aborted.")
    exit()

# Copy the template project
shutil.copytree('template', project_name)
print(f"Template copied with name {project_name}.")

print("Creating project ...")
# Change directory to the new project
os.chdir(project_name)

# Change name in package.json to project name
with open('package.json', 'r') as file:
    filedata = file.read()
filedata = filedata.replace('template', project_name)
with open('package.json', 'w') as file:
    file.write(filedata)
print("Package.json updated.")

# Change name in .env to project name and port
with open('.env', 'r') as file:
    filedata = file.read()
filedata = filedata.replace('template', project_name)
filedata = filedata.replace('3000', str(project_port))
with open('.env', 'w') as file:
    file.write(filedata)
print(".env updated.")

# Change directory to root
os.chdir('..')

# Get entity structure from models.yml
with open('models.yml', 'r') as models_file:
    models = yaml.load(models_file, Loader=yaml.FullLoader)

# Change directory to the prisma folder
os .chdir(project_name)
os.chdir('prisma')

# Add models to schema.prisma
with open('schema.prisma', 'a') as schema_file:
    schema_file.write("\n")
    for model in models:
        schema_file.write(f"model {model['name']} {{\n")
        for field in model['fields']:
            if field['name'] == 'id':
                schema_file.write(f"  {field['name']} {field['type']} @id @default(autoincrement())\n")
            else:
                schema_file.write(f"  {field['name']} {field['type']}\n")
        schema_file.write("}\n")
        schema_file.write("\n")
print("Models added to schema.prisma.")

# Change directory to the root folder
os.chdir('..')
# Change directory to the src folder
os.chdir('src')

# For each model create a directory with the model name and a new controller with crud file and route file
# list of models name to add after to app.js
models_name = []
for model in models:
    model_name = model['name'].lower()
    os.mkdir(model_name)
    os.chdir(model_name)
    print(f"Creating {model_name} controller and routes ...")
    with open(f'{model_name}.controller.js', 'w') as controller_file:
        print(f"Creating {model_name} controller ...")
        controller_file.write(f"const prisma = require('@prisma/client')\n")
        controller_file.write(f"const {{ PrismaClient }} = prisma\n")
        controller_file.write(f"const prismaClient = new PrismaClient()\n")
        controller_file.write("\n")
        # CREATE
        controller_file.write(f"  async create(req, res) {{\n")
        controller_file.write(f"    try {{\n")
        controller_file.write(f"      const {model_name} = await prismaClient.{model_name}.create({{data: req.body}} )\n")
        controller_file.write(f"      return res.status(201).send({model_name})\n")
        controller_file.write(f"    }} catch (error) {{\n")
        controller_file.write(f"      return res.status(400).send({{ error: error.message }})\n")
        controller_file.write(f"    }}\n")
        controller_file.write(f"  }}\n")
        controller_file.write(f"}}\n")
        controller_file.write("\n")
        # GET ALL
        controller_file.write(f"  async getAll(req, res) {{\n")
        controller_file.write(f"    try {{\n")
        controller_file.write(f"      const {model_name}s = await prismaClient.{model_name}.findMany()\n")
        controller_file.write(f"      return res.status(200).send({model_name}s)\n")
        controller_file.write(f"    }} catch (error) {{\n")
        controller_file.write(f"      return res.status(400).send({{ error: error.message }})\n")
        controller_file.write(f"    }}\n")
        # GET ONE BY ID
        controller_file.write(f"  async getOne(req, res) {{\n")
        controller_file.write(f"    try {{\n")
        controller_file.write(f"      const {model_name} = await prismaClient.{model_name}.findUnique({{ where: {{ id: parseInt(req.params.id) }} }})\n")
        controller_file.write(f"      return res.status(200).send({model_name})\n")
        controller_file.write(f"    }} catch (error) {{\n")
        controller_file.write(f"      return res.status(400).send({{ error: error.message }})\n")
        controller_file.write(f"    }}\n")
        # UPDATE BY ID
        controller_file.write(f"  async update(req, res) {{\n")
        controller_file.write(f"    try {{\n")
        controller_file.write(f"      const {model_name} = await prismaClient.{model_name}.update({{ where: {{ id: parseInt(req.params.id) }}, {{data: req.body}} }})\n")
        controller_file.write(f"      return res.status(200).send({model_name})\n")
        controller_file.write(f"    }} catch (error) {{\n")
        controller_file.write(f"      return res.status(400).send({{ error: error.message }})\n")
        controller_file.write(f"    }}\n")
        # DELETE BY ID
        controller_file.write(f"  async delete(req, res) {{\n")
        controller_file.write(f"    try {{\n")
        controller_file.write(f"      await prismaClient.{model_name}.delete({{ where: {{ id: parseInt(req.params.id) }} }})\n")
        controller_file.write(f"      return res.status(204).send()\n")
        controller_file.write(f"    }} catch (error) {{\n")
        controller_file.write(f"      return res.status(400).send({{ error: error.message }})\n")
        controller_file.write(f"    }}\n")
        # EXPORT
        controller_file.write(f"module.exports = new {model_name}Controller()\n")

    with open(f'{model_name}.routes.js', 'w') as routes_file:
        print(f"Creating {model_name} routes ...")
        routes_file.write(f"const express = require('express')\n")
        routes_file.write(f"const {model_name}Controller = require('../controllers/{model_name}_controller')\n")
        routes_file.write(f"const router = express.Router()\n")
        routes_file.write("\n")
        routes_file.write(f"router.post('/', {model_name}Controller.create)\n")
        routes_file.write(f"router.get('/', {model_name}Controller.getAll)\n")
        routes_file.write(f"router.get('/:id', {model_name}Controller.getOne)\n")
        routes_file.write(f"router.put('/:id', {model_name}Controller.update)\n")
        routes_file.write(f"router.delete('/:id', {model_name}Controller.delete)\n")
        routes_file.write("\n")
        routes_file.write(f"module.exports = router\n")
        os.chdir("..")
    # Add to app js the routes
    models_name.append(model_name)

# Change directory to the root folder
os.chdir('..')

# Construct the app.js file
with open('app.js', 'a') as app_file:
    app_file.write(f"const express = require('express')\n")
    app_file.write(f"const app = express()\n")
    for model_name in models_name:
        app_file.write(f"const {model_name}_routes = require('./src/{model_name}/{model_name}.routes')\n")
    app_file.write("\n")
    app_file.write(f"const port = process.env.PORT || 3000\n")
    app_file.write("const project_name = process.env.PROJECT_NAME || 'new_project'\n")
    app_file.write("\n")
    app_file.write(f"app.use(express.json())\n")
    app_file.write("\n")
    for model_name in models_name:
        app_file.write(f"app.use('/{model_name}', {model_name}_routes)\n")
    app_file.write("\n")
    app_file.write(f"app.listen(port, () => console.log(`Server running on port {project_port}`))\n")

print("App.js updated.")