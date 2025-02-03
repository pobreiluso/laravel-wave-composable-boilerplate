DOCKER_COMPOSE := docker-compose -f docker/docker-compose.yaml
APP_SERVICE := app
BUILDER_SERVICE := builder

.PHONY: help init build up down composer-install migrate seed fresh logs bash download-laravel project-check copy-env generate-key download-wave drakarys

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
		$(MAKE) download-laravel; \
	fi
	@$(MAKE) host-env
	@$(MAKE) build
	@$(MAKE) composer-install
	@$(MAKE) npm-install
	@$(MAKE) up
	@$(MAKE) generate-key
	@$(MAKE) wait-for-db
	@$(MAKE) fresh
	@echo "╭────────────────────────────────────────────────────╮"
	@echo "│  \033[1;92m¡Init completado con éxito!\033[0m               │"
	@echo "╰────────────────────────────────────────────────────╯"

build:
	docker build -t app -f docker/Dockerfile .

up:
	$(DOCKER_COMPOSE) up -d

down:
	$(DOCKER_COMPOSE) down

composer-install:
	$(DOCKER_COMPOSE) run --rm $(BUILDER_SERVICE) composer install

npm-install:
	$(DOCKER_COMPOSE) run --rm $(BUILDER_SERVICE) npm install

wait-for-db:
	@echo "Esperando a que MySQL esté disponible..."
	@$(DOCKER_COMPOSE) exec db sh -c '\
	while ! mysqladmin ping -h"localhost" -u"$$MYSQL_USER" -p"$$MYSQL_PASSWORD" --silent; do \
		echo "MySQL no está listo - esperando..."; \
		sleep 2; \
	done; \
	echo "MySQL está listo!"'

migrate: wait-for-db
	$(DOCKER_COMPOSE) run --rm $(BUILDER_SERVICE) php artisan migrate

seed:
	@echo "Comprobando si ya se ha seedado la DB..."
	$(DOCKER_COMPOSE) run --rm $(BUILDER_SERVICE) sh -c '\
	COUNT=$$(php artisan tinker --execute="echo(DB::table('\''migrations'\'')->count())"); \
	if [ "$$COUNT" -eq 0 ]; then \
		echo "-> La DB está vacía. Ejecutando seeds..."; \
		php artisan db:seed; \
	else \
		echo "-> La DB ya contiene migraciones. Omitiendo seed."; \
	fi'

fresh:
	$(DOCKER_COMPOSE) run --rm $(BUILDER_SERVICE) php artisan migrate:fresh --seed

logs:
	$(DOCKER_COMPOSE) logs -f $(APP_SERVICE)

download-laravel:
	@echo "Instalando un nuevo proyecto Laravel desde laravel/laravel..."
	@if [ -d "./code" ]; then \
		echo "Limpiando directorio code..."; \
		rm -rf ./code/*; \
	else \
		mkdir -p ./code; \
	fi
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
			$(MAKE) configure-env; \
		else \
			echo "Ya existe code/.env; no se sobrescribe."; \
			$(MAKE) configure-env; \
		fi; \
	else \
		echo "No existe code/.env.example; ¿seguro que Wave está descargado?"; \
	fi

configure-env:
	@echo "Configurando variables de entorno para los servicios..."
	@if [ -f code/.env ]; then \
		if ! grep -q '^APP_PORT=' code/.env; then \
			echo "APP_PORT=8008" >> code/.env; \
		fi; \
		# Database \
		sed -i '' -e 's/^#*DB_CONNECTION=.*/DB_CONNECTION=mysql/' code/.env; \
		sed -i '' -e 's/^#*DB_HOST=.*/DB_HOST=db/' code/.env; \
		sed -i '' -e 's/^#*DB_PORT=.*/DB_PORT=3306/' code/.env; \
		sed -i '' -e 's/^#*DB_DATABASE=.*/DB_DATABASE=wave/' code/.env; \
		sed -i '' -e 's/^#*DB_USERNAME=.*/DB_USERNAME=wave/' code/.env; \
		sed -i '' -e 's/^#*DB_PASSWORD=.*/DB_PASSWORD=wave/' code/.env; \
		# Redis \
		sed -i '' -e 's/^#*REDIS_HOST=.*/REDIS_HOST=redis/' code/.env; \
		sed -i '' -e 's/^#*REDIS_PASSWORD=.*/REDIS_PASSWORD=null/' code/.env; \
		sed -i '' -e 's/^#*REDIS_PORT=.*/REDIS_PORT=6379/' code/.env; \
		# Mail \
		sed -i '' -e 's/^#*MAIL_MAILER=.*/MAIL_MAILER=smtp/' code/.env; \
		sed -i '' -e 's/^#*MAIL_HOST=.*/MAIL_HOST=mailhog/' code/.env; \
		sed -i '' -e 's/^#*MAIL_PORT=.*/MAIL_PORT=1025/' code/.env; \
		sed -i '' -e 's/^#*MAIL_ENCRYPTION=.*/MAIL_ENCRYPTION=null/' code/.env; \
		echo "Variables de entorno actualizadas correctamente."; \
	else \
		echo "No se encuentra el archivo .env en code/."; \
		exit 1; \
	fi
download-wave:
	@echo "Descargando Wave v3.0.3 en la carpeta ./code..."
	@if [ -d "./code" ] && [ -f "./code/artisan" ]; then \
		echo "Ya existe un proyecto Laravel/Wave en ./code. No se procederá con la descarga..."; \
	else \
		rm -rf ./code && mkdir -p ./code && \
		curl -L https://github.com/thedevdojo/wave/archive/refs/tags/3.0.3.zip -o wave.zip && \
		unzip wave.zip && \
		mv wave-3.0.3/* ./code/ && \
		mv wave-3.0.3/.* ./code/ 2>/dev/null || true && \
		rm -rf wave-3.0.3 wave.zip; \
	fi

drakarys:
	$(DOCKER_COMPOSE) down --volumes
	rm -rf code
	@echo "drakarys"
