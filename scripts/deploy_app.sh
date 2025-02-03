#!/bin/bash
set -e

git clone https://github.com/njdimmer/task_manager_infrastructure.git ~/task_manager
cd ~/task_manager/docker

echo "POSTGRES_USER=${POSTGRES_USER}" >> .env
echo "POSTGRES_PASSWORD=${POSTGRES_PASSWORD}" >> .env
echo "POSTGRES_DB=${POSTGRES_DB}" >> .env
echo "DATABASE_URL=${DATABASE_URL}" >> .env

docker-compose up --build -d