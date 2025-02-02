DOCKER_COMPOSE := docker-compose -f docker/docker-compose.yaml
APP_SERVICE := app
BUILDER_SERVICE := builder

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
	@echo "╭────────────────────────────────────────────────────╮"
	@echo "│  \033[1;96m🚀 Bienvenido al proceso de configuración!\033[0m │"
	@echo "╰────────────────────────────────────────────────────╯"
	$(MAKE) wave-check
	make host-env
	make build
	make composer-install
	make up
	make generate-key
	make migrate
	make seed
	@echo "╭────────────────────────────────────────────────────╮"
	@echo "│  \033[1;92m¡Init completado con éxito!\033[0m               │"
	@echo "╰────────────────────────────────────────────────────╯"

build:
	docker build -t wave-app -f Dockerfile .

up:
	$(DOCKER_COMPOSE) up -d

down:
	$(DOCKER_COMPOSE) down

composer-install:
	$(DOCKER_COMPOSE) run --rm $(BUILDER_SERVICE) composer install

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

download-wave:
	@echo "Skipping download-wave. Now we use a Git submodule for Wave."

bash:
	$(DOCKER_COMPOSE) exec $(APP_SERVICE) bash
wave-check:
	@echo "============================================"
	@echo "   Checking for 'code' submodule..."
	@echo "============================================"
	@if [ -d "./code/.git" ]; then \
		echo "Wave submodule already exists in ./code. Pulling updates..."; \
		git submodule update --remote --merge code || true; \
	else \
		echo "Adding Wave submodule in ./code..."; \
		git submodule add https://github.com/thedevdojo/wave code; \
		echo "Done. Submodule added."; \
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
