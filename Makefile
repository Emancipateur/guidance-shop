THIS_FILE := $(lastword $(MAKEFILE_LIST))
.PHONY: build up stop bash create_network bash_nginx build_from_prod_sql_data build_theme download_prod_sql_dump stop_all_80_port

build_from_prod_sql_data:
	make stop
	make stop_all_80_port
	docker volume rm guidance_dev_guidance_data
	make build

build:
	make create_network
	make stop_all_80_port
	docker-compose -p guidance_dev up -d --build

up:
	make create_network
	make stop_all_80_port
	docker-compose -p guidance_dev up -d --force-recreate

stop:
	docker-compose -p guidance_dev down

bash:
	docker-compose -p guidance_dev exec guidance_shop bash

build_theme:
	docker-compose -p guidance_dev exec guidance_shop bash -c "make assets"

watch:
	docker-compose -p guidance_dev exec guidance_shop bash -c "cd themes/guidance/_dev && npm run watch"

download_prod_sql_dump:
	sshpass -p bfzKh4FArkLkj49xYko7 sftp -P 3522 -R 4096 -B 65536 guidance-export@54.38.121.177:/export.sql ./docker/mariadb/init/999-export.sql

create_network:
	docker network inspect voltagreen >/dev/null 2>&1 || \
	docker network create --driver bridge voltagreen

stop_all_80_port:
	@docker ps --format '{{.ID}} {{.Ports}}' | awk '/0\.0\.0\.0:80->80/ {print $$1}' | xargs -r docker stop
