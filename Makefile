DOCKER_COMPOSE := docker-compose
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
	@echo "🔧🔧🔧🔧🔧━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━🔧🔧🔧🔧🔧"
	@echo "\033[1;96m       🚀 Bienvenido al proceso de configuración!\033[0m"
	@echo "🔧🔧🔧🔧🔧━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━🔧🔧🔧🔧🔧"
	$(MAKE) wave-check
	make host-env
	@echo "Actualizando .env para usar Mariadb..."
	sed -i 's/DB_CONNECTION=sqlite/DB_CONNECTION=mysql/' code/.env
	sed -i 's/#DB_HOST=127.0.0.1/DB_HOST=db/' code/.env
	sed -i 's/#DB_PORT=3306/DB_PORT=3306/' code/.env
	sed -i 's/#DB_DATABASE=database/DB_DATABASE=wave/' code/.env
	sed -i 's/#DB_USERNAME=root/DB_USERNAME=wave/' code/.env
	sed -i 's/#DB_PASSWORD=/DB_PASSWORD=wave/' code/.env
	make build
	make composer-install
	make up
	make generate-key
	make migrate
	make seed
	@echo "🎉🎉🎉━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━🎉🎉🎉"
	@echo "\033[1;92m¡Init completado con éxito!\033[0m"
	@echo "🎉🎉🎉━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━🎉🎉🎉"

build:
	docker build -t wave-app -f Dockerfile .

up:
	$(DOCKER_COMPOSE) up -d

down:
	$(DOCKER_COMPOSE) down

composer-install:
	$(DOCKER_COMPOSE) run --rm $(BUILDER_SERVICE) composer install

migrate:
	$(DOCKER_COMPOSE) exec $(APP_SERVICE) php artisan migrate

seed:
	$(DOCKER_COMPOSE) exec $(APP_SERVICE) php artisan db:seed

fresh:
	$(DOCKER_COMPOSE) exec $(APP_SERVICE) php artisan migrate:fresh --seed

logs:
	$(DOCKER_COMPOSE) logs -f $(APP_SERVICE)

download-wave:
	@echo "Descargando Wave. Si ya existe ./code, se sobrescribirá:"
	@if [ -d "./code" ]; then \
		read -p "¿Sobrescribir la carpeta code? (s/N) " conf; \
		if [ "$$conf" != "s" ] && [ "$$conf" != "S" ]; then \
			echo "Operación cancelada."; \
			exit 1; \
		fi; \
		rm -rf code; \
	fi
	mkdir -p code
	curl -L https://devdojo.com/wave/download -o wave-latest.zip
	unzip wave-latest.zip -d code >/dev/null
	rm wave-latest.zip
	@cd code && SUBDIR="$$(ls -1 | head -n1)" && \
		if [ -d "$$SUBDIR" ]; then \
		   mv $$SUBDIR/* . 2>/dev/null || true; \
		   mv $$SUBDIR/.* . 2>/dev/null || true; \
		   rmdir $$SUBDIR; \
		fi
	@echo "Wave descargado en ./code"

bash:
	$(DOCKER_COMPOSE) exec $(APP_SERVICE) bash
wave-check:
	@echo "============================================"
	@echo "       Verificación de carpeta Wave"
	@echo "============================================"
	@if [ -d "./code" ]; then \
		read -p "Ya existe la carpeta ./code. ¿Deseas sobreescribirla y descargar Wave (s/N)? " conf; \
		if [ "$$conf" = "s" ] || [ "$$conf" = "S" ]; then \
			make download-wave; \
		else \
			echo "Omitiendo descarga. Se usará la carpeta ./code existente."; \
		fi; \
	else \
		make download-wave; \
	fi
copy-env:
	$(DOCKER_COMPOSE) exec $(APP_SERVICE) cp .env.example .env || true
generate-key:
	$(DOCKER_COMPOSE) exec $(APP_SERVICE) php artisan key:generate

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
