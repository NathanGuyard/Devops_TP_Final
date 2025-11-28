"""
Application Flask - Backend API
DevOps Project
"""
import os
import logging
from datetime import datetime
from flask import Flask, jsonify, request
from flask_cors import CORS
import psycopg2
from psycopg2.extras import RealDictCursor
from dotenv import load_dotenv

# Chargement des variables d'environnement
load_dotenv()

# Configuration du logging
logging.basicConfig(
    level=getattr(logging, os.getenv('LOG_LEVEL', 'INFO')),
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Initialisation de l'application Flask
app = Flask(__name__)
CORS(app)

# Configuration
app.config['DATABASE_URL'] = os.getenv('DATABASE_URL')
app.config['DATABASE_URL_READ'] = os.getenv('DATABASE_URL_READ', os.getenv('DATABASE_URL'))
app.config['SECRET_KEY'] = os.getenv('SECRET_KEY', 'dev-secret-key')


def get_db_connection(read_only=False):
    """Obtient une connexion à la base de données."""
    db_url = app.config['DATABASE_URL_READ'] if read_only else app.config['DATABASE_URL']
    try:
        conn = psycopg2.connect(db_url, cursor_factory=RealDictCursor)
        return conn
    except Exception as e:
        logger.error(f"Erreur de connexion à la base de données: {e}")
        return None


def init_db():
    """Initialise la base de données avec les tables nécessaires."""
    conn = get_db_connection()
    if conn:
        try:
            with conn.cursor() as cur:
                cur.execute('''
                    CREATE TABLE IF NOT EXISTS items (
                        id SERIAL PRIMARY KEY,
                        name VARCHAR(255) NOT NULL,
                        description TEXT,
                        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                    )
                ''')
                cur.execute('''
                    CREATE TABLE IF NOT EXISTS health_checks (
                        id SERIAL PRIMARY KEY,
                        server_name VARCHAR(100),
                        checked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                    )
                ''')
                conn.commit()
                logger.info("Base de données initialisée avec succès")
        except Exception as e:
            logger.error(f"Erreur lors de l'initialisation de la DB: {e}")
        finally:
            conn.close()


# ============================================================================
# ROUTES API
# ============================================================================

@app.route('/api/health', methods=['GET'])
def health_check():
    """Endpoint de vérification de santé."""
    db_status = "healthy"
    try:
        conn = get_db_connection(read_only=True)
        if conn:
            with conn.cursor() as cur:
                cur.execute('SELECT 1')
            conn.close()
        else:
            db_status = "unhealthy"
    except Exception:
        db_status = "unhealthy"

    return jsonify({
        'status': 'healthy' if db_status == 'healthy' else 'degraded',
        'timestamp': datetime.utcnow().isoformat(),
        'server': os.getenv('HOSTNAME', 'unknown'),
        'database': db_status,
        'version': '1.0.0'
    })


@app.route('/api/info', methods=['GET'])
def get_info():
    """Retourne les informations du serveur."""
    return jsonify({
        'app_name': os.getenv('APP_NAME', 'DevOps App'),
        'version': '1.0.0',
        'environment': os.getenv('FLASK_ENV', 'production'),
        'server': os.getenv('HOSTNAME', 'unknown'),
        'timestamp': datetime.utcnow().isoformat()
    })


@app.route('/api/items', methods=['GET'])
def get_items():
    """Récupère tous les items."""
    conn = get_db_connection(read_only=True)
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500

    try:
        with conn.cursor() as cur:
            cur.execute('SELECT * FROM items ORDER BY created_at DESC')
            items = cur.fetchall()
        return jsonify({'items': items, 'count': len(items)})
    except Exception as e:
        logger.error(f"Erreur lors de la récupération des items: {e}")
        return jsonify({'error': str(e)}), 500
    finally:
        conn.close()


@app.route('/api/items', methods=['POST'])
def create_item():
    """Crée un nouvel item."""
    data = request.get_json()
    if not data or 'name' not in data:
        return jsonify({'error': 'Name is required'}), 400

    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500

    try:
        with conn.cursor() as cur:
            cur.execute(
                'INSERT INTO items (name, description) VALUES (%s, %s) RETURNING *',
                (data['name'], data.get('description', ''))
            )
            item = cur.fetchone()
            conn.commit()
        return jsonify({'item': item}), 201
    except Exception as e:
        logger.error(f"Erreur lors de la création de l'item: {e}")
        return jsonify({'error': str(e)}), 500
    finally:
        conn.close()


@app.route('/api/items/<int:item_id>', methods=['GET'])
def get_item(item_id):
    """Récupère un item par son ID."""
    conn = get_db_connection(read_only=True)
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500

    try:
        with conn.cursor() as cur:
            cur.execute('SELECT * FROM items WHERE id = %s', (item_id,))
            item = cur.fetchone()
        if item:
            return jsonify({'item': item})
        return jsonify({'error': 'Item not found'}), 404
    except Exception as e:
        logger.error(f"Erreur lors de la récupération de l'item: {e}")
        return jsonify({'error': str(e)}), 500
    finally:
        conn.close()


@app.route('/api/items/<int:item_id>', methods=['PUT'])
def update_item(item_id):
    """Met à jour un item."""
    data = request.get_json()
    if not data:
        return jsonify({'error': 'No data provided'}), 400

    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500

    try:
        with conn.cursor() as cur:
            cur.execute(
                '''UPDATE items
                   SET name = COALESCE(%s, name),
                       description = COALESCE(%s, description),
                       updated_at = CURRENT_TIMESTAMP
                   WHERE id = %s RETURNING *''',
                (data.get('name'), data.get('description'), item_id)
            )
            item = cur.fetchone()
            conn.commit()
        if item:
            return jsonify({'item': item})
        return jsonify({'error': 'Item not found'}), 404
    except Exception as e:
        logger.error(f"Erreur lors de la mise à jour de l'item: {e}")
        return jsonify({'error': str(e)}), 500
    finally:
        conn.close()


@app.route('/api/items/<int:item_id>', methods=['DELETE'])
def delete_item(item_id):
    """Supprime un item."""
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500

    try:
        with conn.cursor() as cur:
            cur.execute('DELETE FROM items WHERE id = %s RETURNING id', (item_id,))
            deleted = cur.fetchone()
            conn.commit()
        if deleted:
            return jsonify({'message': 'Item deleted successfully'})
        return jsonify({'error': 'Item not found'}), 404
    except Exception as e:
        logger.error(f"Erreur lors de la suppression de l'item: {e}")
        return jsonify({'error': str(e)}), 500
    finally:
        conn.close()


@app.route('/api/stats', methods=['GET'])
def get_stats():
    """Retourne des statistiques de l'application."""
    conn = get_db_connection(read_only=True)
    if not conn:
        return jsonify({'error': 'Database connection failed'}), 500

    try:
        with conn.cursor() as cur:
            cur.execute('SELECT COUNT(*) as total FROM items')
            total = cur.fetchone()['total']

            cur.execute('SELECT COUNT(*) as today FROM items WHERE created_at::date = CURRENT_DATE')
            today = cur.fetchone()['today']

        return jsonify({
            'total_items': total,
            'items_today': today,
            'server': os.getenv('HOSTNAME', 'unknown'),
            'timestamp': datetime.utcnow().isoformat()
        })
    except Exception as e:
        logger.error(f"Erreur lors de la récupération des stats: {e}")
        return jsonify({'error': str(e)}), 500
    finally:
        conn.close()


# ============================================================================
# GESTION DES ERREURS
# ============================================================================

@app.errorhandler(404)
def not_found(error):
    return jsonify({'error': 'Endpoint not found'}), 404


@app.errorhandler(500)
def internal_error(error):
    return jsonify({'error': 'Internal server error'}), 500


# ============================================================================
# POINT D'ENTRÉE
# ============================================================================

if __name__ == '__main__':
    init_db()
    port = int(os.getenv('APP_PORT', 3000))
    app.run(host='0.0.0.0', port=port, debug=os.getenv('FLASK_ENV') == 'development')
