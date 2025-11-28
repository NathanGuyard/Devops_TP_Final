#!/bin/bash
set -e

# Création des tables de l'application
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE TABLE IF NOT EXISTS items (
        id SERIAL PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        description TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

    CREATE TABLE IF NOT EXISTS health_checks (
        id SERIAL PRIMARY KEY,
        server_name VARCHAR(100),
        checked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

    -- Insertion de données de test
    INSERT INTO items (name, description) VALUES
        ('Item de test 1', 'Premier item créé automatiquement'),
        ('Item de test 2', 'Deuxième item pour vérifier le fonctionnement');
EOSQL

echo "Base de données initialisée avec succès!"
