
#!/bin/bash

# Script para baixar e instalar o Firebird
wget $FBURL -O /tmp/firebird.tar.xz
mkdir -p $PREFIX
tar -xf /tmp/firebird.tar.xz -C $PREFIX --strip-components=1

# Criar o diretório para salvar firebird.tar.gz
mkdir -p /home/firebird

# Compressão do diretório de instalação em firebird.tar.gz
tar -czf /home/firebird/firebird.tar.gz -C $PREFIX .
