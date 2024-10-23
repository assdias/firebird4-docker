# Etapa de build do Firebird
FROM ubuntu:20.04 AS build

LABEL maintainer="jacob.alberty@foundigital.com"

ARG TARGETPLATFORM
ARG BUILDPLATFORM

ENV PREFIX=/usr/local/firebird
ENV VOLUME=/firebird
ENV DEBIAN_FRONTEND=noninteractive
ENV FBURL=https://github.com/FirebirdSQL/firebird/releases/download/v4.0.2/Firebird-4.0.2.2816-0.tar.xz
ENV DBPATH=/firebird/data

# Criar o diretório fixes e atribuir permissões
RUN mkdir -p /home/fixes && \
    chmod -R +x /home/fixes

# Instalar utilitários necessários
RUN apt-get update && apt-get install -y \
    wget \
    tar \
    xz-utils \
    netcat \
    && rm -rf /var/lib/apt/lists/*

# Copiar o script de build
COPY build.sh ./build.sh

# Executar o script de build
RUN chmod +x ./build.sh && \
    sync && \
    ./build.sh && \
    rm -f ./build.sh

# Etapa final: adicionar Firebird e Adminer
FROM ubuntu:20.04

# Variáveis de ambiente
ENV PREFIX=/usr/local/firebird
ENV VOLUME=/firebird
ENV DEBIAN_FRONTEND=noninteractive
ENV DBPATH=/firebird/data

# Expor portas para Firebird (3050) e Adminer (8080)
EXPOSE 3050/tcp 8080/tcp

# Volume para armazenamento de dados do Firebird
VOLUME ["/firebird"]

# Copiar Firebird do estágio de build
COPY --from=build /home/firebird/firebird.tar.gz /home/firebird/firebird.tar.gz

# Instalar Firebird
COPY install.sh ./install.sh
RUN chmod +x ./install.sh && \
    sync && \
    ./install.sh && \
    rm -f ./install.sh

# Configurar script de inicialização do Firebird
COPY docker-entrypoint.sh ${PREFIX}/docker-entrypoint.sh
RUN chmod +x ${PREFIX}/docker-entrypoint.sh

# Copiar script de verificação de saúde (healthcheck)
COPY docker-healthcheck.sh ${PREFIX}/docker-healthcheck.sh
RUN chmod +x ${PREFIX}/docker-healthcheck.sh && \
    apt-get update && \
    apt-get install -y netcat && \
    rm -rf /var/lib/apt/lists/*

HEALTHCHECK CMD ["${PREFIX}/docker-healthcheck.sh"]

# Instalar PHP e dependências para Adminer
RUN apt-get update && apt-get install -y \
    wget \
    software-properties-common \
    && add-apt-repository ppa:ondrej/php -y \
    && apt-get update && \
    apt-get install -y \
    php \
    php-fpm \
    php-pgsql \
    php-sqlite3 \
    php-mysql \
    php-pear \
    && pecl install firebird && \
    docker-php-ext-enable firebird

# Baixar e configurar o Adminer
RUN mkdir -p /var/www/adminer && \
    wget "https://github.com/vrana/adminer/releases/download/v4.8.1/adminer-4.8.1.php" -O /var/www/adminer/index.php

# Instalar NGINX para servir o Adminer
RUN apt-get install -y nginx

# Copiar o arquivo de configuração do NGINX para o Adminer
COPY adminer.conf /etc/nginx/sites-available/default

# Comandos para iniciar tanto o Firebird quanto o NGINX (Adminer)
CMD ["sh", "-c", "service nginx start && ${PREFIX}/docker-entrypoint.sh && firebird"]
