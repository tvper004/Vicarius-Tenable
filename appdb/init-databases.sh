#!/bin/bash
set -e

# Script de inicialización robusto para PostgreSQL
# Se ejecuta automáticamente en el primer inicio del contenedor

echo "🔧 Iniciando configuración de PostgreSQL..."

# Usar el usuario postgres por defecto para operaciones administrativas
ADMIN_USER="${POSTGRES_USER:-postgres}"
MAIN_DB="${POSTGRES_DB:-vanalyzer}"

# Ejecutar comandos SQL
psql -v ON_ERROR_STOP=0 --username "$ADMIN_USER" --dbname "postgres" <<-EOSQL
    -- Crear usuario vicarius_user si no existe
    DO \$\$
    BEGIN
        IF NOT EXISTS (SELECT FROM pg_user WHERE usename = 'vicarius_user') THEN
            CREATE USER vicarius_user WITH PASSWORD '${POSTGRES_PASSWORD}';
            ALTER USER vicarius_user WITH SUPERUSER;
            RAISE NOTICE 'Usuario vicarius_user creado';
        ELSE
            RAISE NOTICE 'Usuario vicarius_user ya existe';
        END IF;
    END
    \$\$;

    -- Crear base de datos vanalyzer si no existe
    SELECT 'CREATE DATABASE vanalyzer OWNER vicarius_user'
    WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'vanalyzer')\gexec

    -- Crear base de datos metabase si no existe
    SELECT 'CREATE DATABASE metabase OWNER vicarius_user'
    WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'metabase')\gexec

    -- Otorgar todos los permisos
    GRANT ALL PRIVILEGES ON DATABASE vanalyzer TO vicarius_user;
    GRANT ALL PRIVILEGES ON DATABASE metabase TO vicarius_user;
EOSQL

echo "✅ Configuración de PostgreSQL completada"
echo "📊 Bases de datos disponibles:"

# Listar bases de datos
psql -v ON_ERROR_STOP=0 --username "$ADMIN_USER" --dbname "postgres" -c "\l"

