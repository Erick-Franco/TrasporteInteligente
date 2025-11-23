FROM node:18-slim

# Crear usuario no-root para seguridad
RUN useradd --user-group --create-home --shell /bin/false appuser
WORKDIR /usr/src/app

# Copiar package.json primero para aprovechar cache de capas
COPY package*.json ./

# Instalar dependencias de producción
RUN npm ci --production

# Copiar el resto del código
COPY . .

# Cambiar a usuario no-root
USER appuser

EXPOSE 3000

ENV NODE_ENV=production

CMD ["node", "src/app.js"]
