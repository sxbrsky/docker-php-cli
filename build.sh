#!/bin/bash

set -eux;

DOCKER_BUILDKIT=1
DOCKER_REPOSITORY=nulxrd/php-cli

GPG_CHECK=false
LATEST=false
PHP_VERSION="8.3.9"
TARGET_PLATFORM="linux/amd64,linux/arm64"

while [ "$#" -gt 0 ]; do
    case "$1" in
        --version)
            PHP_VERSION="$2"
            shift 2
            ;;
        --platform)
            TARGET_PLATFORM="$2"
            shift 2
            ;;
        --latest)
            LATEST=true
            shift
            ;;
        --gpg_check)
            GPG_CHECK=true
            shift
            ;;
        *)
            echo "Unknown argument: $1"
            echo "Usage: $0 [--version <php_version>] [--platform <platform>] [--latest] [--gpg_check]"
            exit 1;
            ;;
    esac
done

PHP_VERSION_MAJOR=$(echo "${PHP_VERSION}" | grep -oE '^[0-9]+')
PHP_VERSION_MINOR=$(echo "${PHP_VERSION}" | grep -oE '^[0-9]+\.[0-9]+')

docker buildx create --name phpbuilder --use
docker buildx inspect --bootstrap

docker buildx build --platform "${TARGET_PLATFORM}" \
--build-arg PHP_VERSION=${PHP_VERSION} \
--build-arg GPG_CHECK=${GPG_CHECK} \
--tag "${DOCKER_REPOSITORY}:${PHP_VERSION}" \
--tag "${DOCKER_REPOSITORY}:${PHP_VERSION_MAJOR}" \
--tag "${DOCKER_REPOSITORY}:${PHP_VERSION_MINOR}" \
--push .

if [ "$LATEST" = true]; then
    docker tag "${DOCKER_REPOSITORY}:${PHP_VERSION}" "${DOCKER_REPOSITORY}:latest"
    docker push "${DOCKER_REPOSITORY}:latest"
fi

docker buildx stop phpbuilder
docker buildx rm phpbuilder
docker buildx ls
