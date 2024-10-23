#!/bin/bash

# Script para baixar e instalar o Firebird
wget $FBURL -O /tmp/firebird.tar.xz
mkdir -p $PREFIX
tar -xf /tmp/firebird.tar.xz -C $PREFIX --strip-components=1
