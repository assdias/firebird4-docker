#!/bin/bash
set -e

# Inicializa o Firebird
if [ "$1" = 'firebird' ]; then
    exec /usr/local/firebird/bin/fbguard -forever
fi

exec "$@"
