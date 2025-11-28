/**
 * Application Frontend - DevOps Project
 */

const API_BASE = '/api';

// ============================================================================
// INITIALISATION
// ============================================================================

document.addEventListener('DOMContentLoaded', () => {
    checkHealth();
    loadItems();
    loadStats();

    // Formulaire d'ajout d'item
    document.getElementById('item-form').addEventListener('submit', handleAddItem);

    // Rafraîchissement automatique toutes les 30 secondes
    setInterval(() => {
        checkHealth();
        loadStats();
    }, 30000);
});

// ============================================================================
// HEALTH CHECK
// ============================================================================

async function checkHealth() {
    try {
        const response = await fetch(`${API_BASE}/health`);
        const data = await response.json();

        // Mise à jour des indicateurs
        updateStatusIndicator('api-status', data.status);
        updateStatusIndicator('db-status', data.database);
        document.getElementById('server-name').textContent = data.server;
        document.getElementById('footer-server').textContent = data.server;

    } catch (error) {
        console.error('Health check failed:', error);
        updateStatusIndicator('api-status', 'unhealthy');
        updateStatusIndicator('db-status', 'unhealthy');
    }
}

function updateStatusIndicator(elementId, status) {
    const element = document.getElementById(elementId);
    element.textContent = status;
    element.className = 'status-indicator ' + status;
}

// ============================================================================
// ITEMS CRUD
// ============================================================================

async function loadItems() {
    const listElement = document.getElementById('items-list');

    try {
        const response = await fetch(`${API_BASE}/items`);
        const data = await response.json();

        if (data.items && data.items.length > 0) {
            listElement.innerHTML = data.items.map(item => createItemHTML(item)).join('');
        } else {
            listElement.innerHTML = '<p class="no-items">Aucun item pour le moment. Ajoutez-en un !</p>';
        }
    } catch (error) {
        console.error('Failed to load items:', error);
        listElement.innerHTML = '<p class="loading">Erreur lors du chargement des items</p>';
    }
}

function createItemHTML(item) {
    const date = new Date(item.created_at).toLocaleDateString('fr-FR', {
        day: '2-digit',
        month: '2-digit',
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
    });

    return `
        <div class="item" data-id="${item.id}">
            <div class="item-info">
                <h3>${escapeHTML(item.name)}</h3>
                <p>${escapeHTML(item.description || 'Pas de description')}</p>
                <span class="item-date">${date}</span>
            </div>
            <button class="btn btn-danger" onclick="deleteItem(${item.id})">Supprimer</button>
        </div>
    `;
}

async function handleAddItem(event) {
    event.preventDefault();

    const nameInput = document.getElementById('item-name');
    const descInput = document.getElementById('item-description');

    const item = {
        name: nameInput.value.trim(),
        description: descInput.value.trim()
    };

    if (!item.name) {
        alert('Le nom est requis');
        return;
    }

    try {
        const response = await fetch(`${API_BASE}/items`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(item)
        });

        if (response.ok) {
            nameInput.value = '';
            descInput.value = '';
            loadItems();
            loadStats();
        } else {
            const error = await response.json();
            alert('Erreur: ' + error.error);
        }
    } catch (error) {
        console.error('Failed to add item:', error);
        alert('Erreur lors de l\'ajout de l\'item');
    }
}

async function deleteItem(id) {
    if (!confirm('Êtes-vous sûr de vouloir supprimer cet item ?')) {
        return;
    }

    try {
        const response = await fetch(`${API_BASE}/items/${id}`, {
            method: 'DELETE'
        });

        if (response.ok) {
            loadItems();
            loadStats();
        } else {
            const error = await response.json();
            alert('Erreur: ' + error.error);
        }
    } catch (error) {
        console.error('Failed to delete item:', error);
        alert('Erreur lors de la suppression');
    }
}

// ============================================================================
// STATISTICS
// ============================================================================

async function loadStats() {
    try {
        const response = await fetch(`${API_BASE}/stats`);
        const data = await response.json();

        document.getElementById('total-items').textContent = data.total_items;
        document.getElementById('items-today').textContent = data.items_today;

    } catch (error) {
        console.error('Failed to load stats:', error);
    }
}

// ============================================================================
// UTILITIES
// ============================================================================

function escapeHTML(str) {
    if (!str) return '';
    const div = document.createElement('div');
    div.textContent = str;
    return div.innerHTML;
}
