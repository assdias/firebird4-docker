#!/bin/bash

# Verificar se o Firebird está rodando na porta 3050
if nc -z localhost 3050; then
  exit 0
else
  exit 1
fi
