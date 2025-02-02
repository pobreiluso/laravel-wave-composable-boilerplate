# Wave - Local Project

This repository contains the configuration and tooling necessary to initialize and run a Wave-based project with Docker containers. Below is a step-by-step guide on how to spin up the environment, install dependencies, and perform common tasks.

---

## 1. Prerequisites

• Docker installed and running.  
• docker-compose available on your system.  
• Optionally, Make (GNU make) installed to run simplified commands.

---

## 2. Cloning or Downloading the Project

1. Clone this repository to your local environment:
   git clone https://your-url-here.com/username/wave-repo.git

2. Navigate into the project folder:
   cd wave-repo

---

## 3. Initializing the Project

Use the “init” command from the Makefile to set up everything:

   make init

This command will:  
• Check if the ./code folder already exists, prompting you if you want to download Wave.  
• Copy the .env.example file to .env (if it doesn’t exist).  
• Switch the DB connection to MySQL/MariaDB.  
• Build the Docker image (make build).  
• Install Composer dependencies (make composer-install).  
• Start up the containers in detached mode (make up).  
• Generate a new Laravel APP_KEY (make generate-key).  
• Run database migrations (make migrate).  
• Seed the database (make seed).

Once this process finishes, you should be able to access the application at http://localhost:8008 (or whichever port is set by APP_PORT in your .env).

---

## 4. Common Commands

Below are the most common commands found in the Makefile:

1) Start Containers  
   make up  
   Spin up all services in detached mode (equivalent to docker-compose up -d).

2) Stop Containers  
   make down  
   Stop and remove the containers (equivalent to docker-compose down).

3) Build the Docker Image  
   make build  
   Rebuild the wave-app image if you modified the Dockerfile.

4) Install Composer Dependencies  
   make composer-install  
   Runs composer install inside the builder container.

5) Run Database Migrations  
   make migrate  
   Runs php artisan migrate inside the builder container.

6) Seed the Database  
   make seed  
   Checks if the database is empty before seeding. Avoids double seeding when migrations already exist.

7) Refresh the Database  
   make fresh  
   Cleans all tables and re-runs the migrations, then seeds the database.

8) View Logs  
   make logs  
   Shows logs of the app service (wave-app container).

9) Open a Bash Shell in the App Container  
   make bash  
   Executes a bash shell inside the wave-app container.

10) Download Wave Manually  
   make download-wave  
   Optionally used if you just want to overwrite the ./code folder with a fresh Wave copy.

---

## 5. File Structure

• code/  
  The main folder where Wave is downloaded (Laravel app code).  
• docker-compose.yaml  
  Defines services: builder, app, nginx, db.  
• Dockerfile  
  Multi-stage build with base, builder, and app stages.  
• Makefile  
  Contains targets for common operations (init, build, up, down, migrate, etc.).  
• nginx/  
  Contains Nginx config (nginx.conf) that maps requests to PHP-FPM.  
• .env  
  The environment file copied from ./code/.env.example. Holds DB, port, and app config.  

---

## 6. Final Notes

• If you make core changes to Wave, refer to the official documentation at [devdojo.com/wave/docs](https://devdojo.com/wave/docs).  
• To keep your changes separate from Wave’s code, consider creating a separate Laravel package or using a submodule approach.  
• For production deployments, be sure to include optimization steps (caching config, routes, etc.) and possibly generate a single Docker image with your code and built assets.
