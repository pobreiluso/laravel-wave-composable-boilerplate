DOCKER_COMPOSE := docker-compose -f docker/docker-compose.yaml
APP_SERVICE := app
BUILDER_SERVICE := builder

.PHONY: help init build up down composer-install migrate seed fresh logs bash download-laravel project-check copy-env generate-key download-wave

help:
	@echo "Comandos disponibles:"
	@echo "  make init       - Inicializa el proyecto (contenedores, .env, dependencias, migraciones, seeds)."
	@echo "  make download-wave - Descarga la última versión de Wave."
	@echo "  make build      - Construye la imagen (si tienes un Dockerfile personalizado)."
	@echo "  make up         - Levanta los contenedores en segundo plano."
	@echo "  make project-check - Verifica si ya existe un proyecto Laravel, de lo contrario llama a download-laravel."
	@echo "  make down       - Detiene y elimina los contenedores."
	@echo "  make composer-install - Instala dependencias de Composer en el contenedor."
	@echo "  make migrate    - Ejecuta las migraciones."
	@echo "  make seed       - Ejecuta el seeding de la base de datos."
	@echo "  make fresh      - Limpia migraciones y vuelve a migrar y seedear la base de datos."
	@echo "  make logs       - Muestra los logs del servicio app."
	@echo "  make bash       - Entra a la terminal bash del contenedor app."

init:
	@echo "╭────────────────────────────────────────────────────╮"
	@echo "│  \033[1;96m🚀 Bienvenido al proceso de configuración!\033[0m │"
	@echo "╰────────────────────────────────────────────────────╯"
	@read -p "¿Deseas clonar Wave desde su repositorio oficial o instalar Laravel (wave/laravel)? " choice; \
	if [ "$$choice" = "wave" ]; then \
		$(MAKE) download-wave; \
	else \
		$(MAKE) project-check; \
	fi
	make host-env
	make build
	make composer-install
	make npm-install
	make up
	make generate-key
	make migrate
	make seed
	@echo "╭────────────────────────────────────────────────────╮"
	@echo "│  \033[1;92m¡Init completado con éxito!\033[0m               │"
	@echo "╰────────────────────────────────────────────────────╯"

build:
	docker build -t wave-app -f docker/Dockerfile .

up:
	$(DOCKER_COMPOSE) up -d

down:
	$(DOCKER_COMPOSE) down

composer-install:
	$(DOCKER_COMPOSE) run --rm $(BUILDER_SERVICE) composer install

npm-install:
	$(DOCKER_COMPOSE) run --rm $(BUILDER_SERVICE) npm install

migrate:
	$(DOCKER_COMPOSE) run --rm $(BUILDER_SERVICE) php artisan migrate

seed:
	@echo "Comprobando si ya se ha seedado la DB..."
	$(DOCKER_COMPOSE) run --rm $(BUILDER_SERVICE) sh -c "\
	COUNT=\$$(php artisan tinker --execute=\"echo(DB::table('migrations')->count())\"); \
	if [ \$\$COUNT -eq 0 ]; then \
		echo '-> La DB está vacía. Ejecutando seeds...'; \
		php artisan db:seed; \
	else \
		echo '-> La DB ya contiene migraciones. Omitiendo seed.'; \
	fi"

fresh:
	$(DOCKER_COMPOSE) run --rm $(BUILDER_SERVICE) php artisan migrate:fresh --seed

logs:
	$(DOCKER_COMPOSE) logs -f $(APP_SERVICE)

download-laravel:
	@echo "Instalando un nuevo proyecto Laravel desde laravel/laravel..."
	$(DOCKER_COMPOSE) run --rm $(BUILDER_SERVICE) composer create-project laravel/laravel .

bash:
	$(DOCKER_COMPOSE) exec $(APP_SERVICE) bash
project-check:
	@echo "============================================"
	@echo "  Checking if code folder has a Laravel project..."
	@echo "============================================"
	@if [ -f "./code/artisan" ]; then \
		echo "Laravel project already existe en ./code. Omitiendo descarga..."; \
	else \
		$(MAKE) download-laravel; \
	fi
copy-env:
	$(DOCKER_COMPOSE) exec $(APP_SERVICE) cp .env.example .env || true
generate-key:
	$(DOCKER_COMPOSE) run $(BUILDER_SERVICE) php artisan key:generate

host-env:
	@if [ -f code/.env.example ]; then \
		if [ ! -f code/.env ]; then \
			echo "Copiando code/.env.example → code/.env"; \
			cp code/.env.example code/.env; \
			if ! grep -q '^APP_PORT=' code/.env; then \
				echo "APP_PORT=8008" >> code/.env; \
			fi; \
			sed -i 's/^DB_CONNECTION=.*/DB_CONNECTION=mysql/' code/.env; \
			sed -i 's/^DB_DATABASE=.*/DB_DATABASE=wave/' code/.env; \
			sed -i 's/^DB_USERNAME=.*/DB_USERNAME=wave/' code/.env; \
			sed -i 's/^DB_PASSWORD=.*/DB_PASSWORD=wave/' code/.env; \
		else \
			echo "Ya existe code/.env; no se sobrescribe."; \
			if ! grep -q '^APP_PORT=' code/.env; then \
				echo "No APP_PORT en code/.env; añadiendo APP_PORT=8008"; \
				echo "APP_PORT=8008" >> code/.env; \
			fi; \
		fi; \
	else \
		echo "No existe code/.env.example; ¿seguro que Wave está descargado?"; \
	fi
download-wave:
	@echo "Clonando Wave en la carpeta ./code..."
	@if [ -d "./code" ] && [ -f "./code/artisan" ]; then \
		echo "Ya existe un proyecto Laravel/Wave en ./code. No se procederá con el clon..."; \
	else \
		rm -rf ./code; \
		git clone git@github.com:thedevdojo/wave.git code; \
	fi
