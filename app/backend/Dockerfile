FROM python:3.11-slim

WORKDIR /app

# Installation des dépendances système
RUN apt-get update && apt-get install -y \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Copie des requirements et installation
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt gunicorn

# Copie du code
COPY app.py .

# Exposition du port
EXPOSE 3000

# Démarrage avec Gunicorn
CMD ["gunicorn", "--workers", "2", "--bind", "0.0.0.0:3000", "app:app"]
