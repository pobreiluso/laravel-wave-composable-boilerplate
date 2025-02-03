# Wave Docker Development Environment

Este repositorio contiene la configuración necesaria para ejecutar Wave v3.0.3 en un entorno Docker local. A continuación se detalla cómo inicializar y gestionar el entorno de desarrollo.

## Prerrequisitos

- Docker instalado y en ejecución
- docker-compose disponible en el sistema
- Make (GNU make) instalado para ejecutar comandos simplificados

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

## Estructura del Proyecto

```
.
├── code/                   # Código fuente de Wave
├── docker/
│   ├── .env.docker        # Variables de entorno para Docker
│   ├── Dockerfile         # Multi-stage build (base, builder, app)
│   ├── docker-compose.yaml # Definición de servicios
│   └── nginx/
│       └── nginx.conf     # Configuración de Nginx
└── Makefile               # Comandos simplificados
```

## Comandos Disponibles

### Gestión del Entorno

- `make up` - Inicia los contenedores
- `make down` - Detiene y elimina los contenedores
- `make build` - Construye la imagen Docker
- `make logs` - Muestra los logs del servicio app
- `make bash` - Abre una terminal en el contenedor app

### Base de Datos

- `make migrate` - Ejecuta las migraciones
- `make seed` - Ejecuta los seeders
- `make fresh` - Recrea y puebla la base de datos

### Dependencias

- `make composer-install` - Instala dependencias de Composer
- `make npm-install` - Instala dependencias de NPM

### Utilidades

- `make drakarys` - Elimina todos los contenedores y el código (¡usar con precaución!)
- `make download-wave` - Descarga Wave v3.0.3 (solo si ./code está vacío)

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
