.PHONY: init up down composer-install migrate seed fresh

# Inicializa el proyecto (levanta contenedores, copia .env, instala dependencias, genera key de Laravel, migra y seed).
init:
	docker-compose up -d
	docker-compose exec app cp .env.example .env || true
	docker-compose exec app composer install
	docker-compose exec app php artisan key:generate
	docker-compose exec app php artisan migrate
	docker-compose exec app php artisan db:seed

# Levanta los contenedores en segundo plano
up:
	docker-compose up -d

# Detiene y elimina los contenedores
down:
	docker-compose down

# Instala dependencias de Composer dentro del contenedor
composer-install:
	docker-compose exec app composer install

# Ejecuta las migraciones
migrate:
	docker-compose exec app php artisan migrate

# Hace el seed de la base de datos
seed:
	docker-compose exec app php artisan db:seed

# Elimina y reinicia la base de datos
fresh:
	docker-compose exec app php artisan migrate:fresh --seed
