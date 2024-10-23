# Etapa de build do Firebird
FROM ubuntu:20.04 AS build

LABEL maintainer="jacob.alberty@foundigital.com"

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

# Etapa final: adicionar Firebird
FROM ubuntu:20.04

# Variáveis de ambiente
ENV PREFIX=/usr/local/firebird
ENV VOLUME=/firebird
ENV DEBIAN_FRONTEND=noninteractive
ENV DBPATH=/firebird/data

# Expor porta para Firebird (3050)
EXPOSE 3050/tcp

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

# Comandos para iniciar o Firebird
CMD ["${PREFIX}/docker-entrypoint.sh", "firebird"]
