# Makefile for Docker Nginx PHP Composer MySQL

include .env

# MySQL
MYSQL_DUMPS_DIR=data/db/dumps

help:
	@echo ""
	@echo "usage: make COMMAND"
	@echo ""
	@echo "Commands:"
	@echo "  clean               Clean directories for reset"
	@echo "  hard-clean          Clean web directory for reset"
	@echo "  composer-up         Update PHP dependencies with composer"
	@echo "  docker-up           Create and start containers"
	@echo "  docker-stop         Stop all services"
	@echo "  docker-down         Stop and clear all services"
	@echo "  gen-certs           Generate SSL certificates"
	@echo "  logs                Follow log output"
	@echo "  mysql-dump          Create backup of all databases"
	@echo "  mysql-restore       Restore backup of all databases"

init-new:
	@composer create-project --prefer-dist laravel/laravel web
	@make docker-up
	@make php-composer-install
	@make php-install-ext
	@make fixReadWrite

init-existing:
	@git clone <your-repo> web
	@make docker-up
	@make composer-up
	@make php-composer-install
	@make php-install-ext
	@make fixReadWrite

clean:
	@rm -Rf data/db/mysql/*
	@rm -Rf $(MYSQL_DUMPS_DIR)/*
	@rm -Rf web/vendor
	@rm -Rf web/composer.lock
	@rm -Rf etc/ssl/*
	
hard-clean:
	@make clean
	@rm -Rf web
	@mkdir web

php-composer-install:
	@docker exec -i $(shell docker-compose ps -q php) apt update
	@docker exec -i $(shell docker-compose ps -q php) apt install wget
	@docker exec -i $(shell docker-compose ps -q php) wget https://raw.githubusercontent.com/composer/getcomposer.org/1b137f8bf6db3e79a38a5bc45324414a6b1f9df2/web/installer
	@docker exec -i $(shell docker-compose ps -q php) php installer
	@docker exec -i $(shell docker-compose ps -q php) rm ./installer
	@docker exec -i $(shell docker-compose ps -q php) mv ./composer.phar /usr/local/bin/composer
	
php-install-ext:
	@docker exec -i $(shell docker-compose ps -q php) docker-php-ext-install intl
	
composer-post-install:
	@docker exec -i $(shell docker-compose ps -q php) composer run-script post-install-cmd

composer-up:
	@docker run --rm -v $(shell pwd)/web/:/app composer update

composer-install:
	@docker run --rm -v $(shell pwd)/web/:/app composer install

docker-up:
	docker-compose up -d

docker-stop:
	@docker-compose stop

docker-down:
	@docker-compose down

gen-certs:
	@docker run --rm -v $(shell pwd)/etc/ssl:/certificates -e "SERVER=$(NGINX_HOST)" jacoelho/generate-certificate

logs:
	@docker-compose logs -f

mysql-dump:
	@mkdir -p $(MYSQL_DUMPS_DIR)
	@docker exec $(shell docker-compose ps -q mysqldb) mysqldump --all-databases -u"$(MYSQL_ROOT_USER)" -p"$(MYSQL_ROOT_PASSWORD)" > $(MYSQL_DUMPS_DIR)/db.sql 2>/dev/null
	@make resetOwner

mysql-restore:
	@docker exec -i $(shell docker-compose ps -q mysqldb) mysql -u"$(MYSQL_ROOT_USER)" -p"$(MYSQL_ROOT_PASSWORD)" < $(MYSQL_DUMPS_DIR)/db.sql 2>/dev/null

phpmd:
	@docker-compose exec -T php \
	./app/vendor/bin/phpmd \
	./app/src \
	text cleancode,codesize,controversial,design,naming,unusedcode

test: code-sniff
	@docker-compose exec -T php ./app/vendor/bin/phpunit --colors=always --configuration ./app/
	@make resetOwner

resetOwner:
	@$(shell chown -Rf $(SUDO_USER):$(shell id -g -n $(SUDO_USER)) $(MYSQL_DUMPS_DIR) "$(shell pwd)/etc/ssl" "$(shell pwd)/web/var" 2> /dev/null)

fixPermissions:
	@sudo chmod -Rf 777 ./web/var/

fixReadWrite:
	@sudo chmod -Rf 777 ./web/
	
root:
	@docker exec -it -u root $$(docker-compose ps -q php) /bin/bash

nginx-root:
	@docker exec -it -u root $$(docker-compose ps -q web) /bin/bash

create-db:
	@make migrate
	@make seed

migrate:
	@docker exec -i $(shell docker-compose ps -q php) php artisan migrate

seed:
	@docker exec -i $(shell docker-compose ps -q php) php artisan db:seed

.PHONY: clean init
