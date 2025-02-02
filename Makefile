DOCKER_COMPOSE := docker-compose
APP_SERVICE := app

.PHONY: help init build up down composer-install migrate seed fresh logs bash

help:
	@echo "Comandos disponibles:"
	@echo "  make init       - Inicializa el proyecto (contenedores, .env, dependencias, migraciones, seeds)."
	@echo "  make build      - Construye la imagen (si tienes un Dockerfile personalizado)."
	@echo "  make up         - Levanta los contenedores en segundo plano."
	@echo "  make down       - Detiene y elimina los contenedores."
	@echo "  make composer-install - Instala dependencias de Composer en el contenedor."
	@echo "  make migrate    - Ejecuta las migraciones."
	@echo "  make seed       - Ejecuta el seeding de la base de datos."
	@echo "  make fresh      - Limpia migraciones y vuelve a migrar y seedear la base de datos."
	@echo "  make logs       - Muestra los logs del servicio app."
	@echo "  make bash       - Entra a la terminal bash del contenedor app."

init:
	$(DOCKER_COMPOSE) up -d
	$(DOCKER_COMPOSE) exec $(APP_SERVICE) cp .env.example .env || true
	$(DOCKER_COMPOSE) exec $(APP_SERVICE) composer install
	$(DOCKER_COMPOSE) exec $(APP_SERVICE) php artisan key:generate
	$(DOCKER_COMPOSE) exec $(APP_SERVICE) php artisan migrate
	$(DOCKER_COMPOSE) exec $(APP_SERVICE) php artisan db:seed

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

bash:
	$(DOCKER_COMPOSE) exec $(APP_SERVICE) bash
