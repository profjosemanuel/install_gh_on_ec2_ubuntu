#!/bin/bash

# Verificar si el usuario tiene permisos de root
if [ "$(id -u)" -ne 0 ]; then
    echo "Este script debe ejecutarse con permisos de root."
    exit 1
fi

# Verificar si wget está instalado
if ! type -p wget >/dev/null; then
    echo "wget no está instalado. Instalando wget..."
    apt update
    apt-get install wget -y
else
    echo "wget ya está instalado."
fi

# Crear el directorio de claves si no existe
if [ ! -d /etc/apt/keyrings ]; then
    echo "Creando el directorio /etc/apt/keyrings..."
    mkdir -p -m 755 /etc/apt/keyrings
else
    echo "El directorio /etc/apt/keyrings ya existe."
fi

# Descargar y configurar la clave de archivo
out=$(mktemp)
echo "Descargando la clave del archivo..."
wget -nv -O "$out" https://cli.github.com/packages/githubcli-archive-keyring.gpg

if [ $? -eq 0 ]; then
    echo "Clave descargada correctamente. Configurando..."
    cat "$out" | tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
    chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
else
    echo "Error al descargar la clave. Saliendo..."
    exit 1
fi

# Agregar el repositorio de GitHub CLI
arch=$(dpkg --print-architecture)
echo "Agregando el repositorio de GitHub CLI..."
echo "deb [arch=$arch signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list

# Actualizar repositorios e instalar gh
echo "Actualizando los repositorios..."
apt update

if [ $? -eq 0 ]; then
    echo "Instalando GitHub CLI..."
    apt install gh -y
    if [ $? -eq 0 ]; then
        echo "GitHub CLI instalado correctamente."
    else
        echo "Error al instalar GitHub CLI."
        exit 1
    fi
else
    echo "Error al actualizar los repositorios. Saliendo..."
    exit 1
fi
