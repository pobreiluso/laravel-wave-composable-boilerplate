DOCKER_COMPOSE := docker-compose
APP_SERVICE := app

.PHONY: help init build up down composer-install migrate seed fresh logs bash download-wave wave-check copy-env generate-key

help:
	@echo "Comandos disponibles:"
	@echo "  make init       - Inicializa el proyecto (contenedores, .env, dependencias, migraciones, seeds)."
	@echo "  make download-wave - Descarga la última versión de Wave."
	@echo "  make build      - Construye la imagen (si tienes un Dockerfile personalizado)."
	@echo "  make up         - Levanta los contenedores en segundo plano."
	@echo "  make wave-check - Verifica si ya existe el directorio wave, de lo contrario llama a download-wave."
	@echo "  make down       - Detiene y elimina los contenedores."
	@echo "  make composer-install - Instala dependencias de Composer en el contenedor."
	@echo "  make migrate    - Ejecuta las migraciones."
	@echo "  make seed       - Ejecuta el seeding de la base de datos."
	@echo "  make fresh      - Limpia migraciones y vuelve a migrar y seedear la base de datos."
	@echo "  make logs       - Muestra los logs del servicio app."
	@echo "  make bash       - Entra a la terminal bash del contenedor app."

init:
	make host-env
	$(MAKE) wave-check
	make up
	make copy-env
	make composer-install
	make generate-key
	make migrate
	make seed
	@echo "Init completado."

build:
	$(DOCKER_COMPOSE) build

up:
	$(DOCKER_COMPOSE) up -d

down:
	$(DOCKER_COMPOSE) down

composer-install:
	$(DOCKER_COMPOSE) exec $(APP_SERVICE) composer install

migrate:
	$(DOCKER_COMPOSE) exec $(APP_SERVICE) php artisan migrate

seed:
	$(DOCKER_COMPOSE) exec $(APP_SERVICE) php artisan db:seed

fresh:
	$(DOCKER_COMPOSE) exec $(APP_SERVICE) php artisan migrate:fresh --seed

logs:
	$(DOCKER_COMPOSE) logs -f $(APP_SERVICE)

download-wave:
	@echo "Descargando Wave. Si ya existe ./wave, se sobrescribirá:"
	@if [ -d "./wave" ]; then \
		read -p "¿Sobrescribir la carpeta wave? (s/N) " conf; \
		if [ "$$conf" != "s" ] && [ "$$conf" != "S" ]; then \
			echo "Operación cancelada."; \
			exit 1; \
		fi; \
		rm -rf wave; \
	fi
	curl -L https://devdojo.com/wave/download -o wave-latest.zip
	unzip wave-latest.zip -d wave
	rm wave-latest.zip
	@echo "Wave descargado en ./wave"

bash:
	$(DOCKER_COMPOSE) exec $(APP_SERVICE) bash
wave-check:
	@if [ -d "./wave" ]; then \
		echo "El directorio ./wave ya existe."; \
		echo "Si quieres descargarlo de nuevo, elimínalo o renómbralo antes de ejecutar make download-wave."; \
	else \
		make download-wave; \
	fi
copy-env:
	$(DOCKER_COMPOSE) exec $(APP_SERVICE) cp .env.example .env || true
generate-key:
	$(DOCKER_COMPOSE) exec $(APP_SERVICE) php artisan key:generate

host-env:
	cp .env.example .env || true
