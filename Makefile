DOCKER_COMPOSE := docker-compose -f docker/docker-compose.yaml
APP_SERVICE := app
BUILDER_SERVICE := builder
TIMESTAMP := $(shell date +%Y%m%d_%H%M%S)
BACKUP_DIR := ./backups
ENV_FILE := code/.env

.PHONY: help init build up down composer-install migrate seed fresh logs bash download-laravel project-check copy-env generate-key download-wave drakarys test cache-clear logs-all backup restore xdebug ssl-cert install-dev install-prod status

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
	make wait-for-db
	make fresh
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
			sed -i '' 's/^#*DB_CONNECTION=.*/DB_CONNECTION=mysql/' code/.env; \
			sed -i '' 's/^#*DB_HOST=.*/DB_HOST=db/' code/.env; \
			sed -i '' 's/^#*DB_PORT=.*/DB_PORT=3306/' code/.env; \
			sed -i '' 's/^#*DB_DATABASE=.*/DB_DATABASE=wave/' code/.env; \
			sed -i '' 's/^#*DB_USERNAME=.*/DB_USERNAME=wave/' code/.env; \
			sed -i '' 's/^#*DB_PASSWORD=.*/DB_PASSWORD=wave/' code/.env; \
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

test:
	@echo "🧪 Ejecutando tests..."
	$(DOCKER_COMPOSE) run --rm $(BUILDER_SERVICE) php artisan test

cache-clear:
	@echo "🧹 Limpiando caché..."
	$(DOCKER_COMPOSE) run --rm $(BUILDER_SERVICE) php artisan cache:clear
	$(DOCKER_COMPOSE) run --rm $(BUILDER_SERVICE) php artisan config:clear
	$(DOCKER_COMPOSE) run --rm $(BUILDER_SERVICE) php artisan route:clear
	$(DOCKER_COMPOSE) run --rm $(BUILDER_SERVICE) php artisan view:clear
	@echo "✨ Caché limpiada"

logs-all:
	$(DOCKER_COMPOSE) logs -f

backup:
	@mkdir -p $(BACKUP_DIR)
	@echo "📦 Creando backup de la base de datos..."
	$(DOCKER_COMPOSE) exec db mysqldump -u$${MYSQL_USER} -p$${MYSQL_PASSWORD} $${MYSQL_DATABASE} > $(BACKUP_DIR)/backup_$(TIMESTAMP).sql
	@echo "✅ Backup creado en $(BACKUP_DIR)/backup_$(TIMESTAMP).sql"

restore:
	@echo "🔄 Restaurando último backup..."
	@LATEST_BACKUP=$$(ls -t $(BACKUP_DIR)/*.sql | head -1); \
	if [ -n "$$LATEST_BACKUP" ]; then \
		$(DOCKER_COMPOSE) exec -T db mysql -u$${MYSQL_USER} -p$${MYSQL_PASSWORD} $${MYSQL_DATABASE} < $$LATEST_BACKUP; \
		echo "✅ Base de datos restaurada desde $$LATEST_BACKUP"; \
	else \
		echo "❌ No se encontraron backups"; \
	fi

xdebug:
	@echo "🔧 Configurando Xdebug..."
	$(DOCKER_COMPOSE) exec $(APP_SERVICE) bash -c '\
		pecl install xdebug && \
		docker-php-ext-enable xdebug && \
		echo "xdebug.mode=debug" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini && \
		echo "xdebug.client_host=host.docker.internal" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini'
	$(DOCKER_COMPOSE) restart $(APP_SERVICE)
	@echo "✅ Xdebug instalado y configurado"

ssl-cert:
	@echo "🔒 Generando certificados SSL auto-firmados..."
	@mkdir -p docker/nginx/ssl
	@openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
		-keyout docker/nginx/ssl/nginx.key \
		-out docker/nginx/ssl/nginx.crt \
		-subj "/C=ES/ST=State/L=City/O=Organization/CN=localhost"
	@echo "✅ Certificados generados"

install-dev: init
	@echo "🛠️ Configurando entorno de desarrollo..."
	make xdebug
	$(DOCKER_COMPOSE) run --rm $(BUILDER_SERVICE) composer install --optimize-autoloader
	$(DOCKER_COMPOSE) run --rm $(BUILDER_SERVICE) npm install
	@echo "✅ Entorno de desarrollo configurado"

install-prod:
	@echo "🚀 Configurando entorno de producción..."
	$(DOCKER_COMPOSE) run --rm $(BUILDER_SERVICE) composer install --no-dev --optimize-autoloader
	$(DOCKER_COMPOSE) run --rm $(BUILDER_SERVICE) npm install --production
	$(DOCKER_COMPOSE) run --rm $(BUILDER_SERVICE) npm run build
	make cache-clear
	@echo "✅ Entorno de producción configurado"

status:
	@echo "📊 Estado de los contenedores:"
	@$(DOCKER_COMPOSE) ps
	@echo "\n💾 Espacio en disco:"
	@docker system df
	@echo "\n🔍 Variables de entorno cargadas:"
	@if [ -f $(ENV_FILE) ]; then \
		grep -v '^#' $(ENV_FILE) | grep .; \
	else \
		echo "❌ Archivo .env no encontrado"; \
	fi
