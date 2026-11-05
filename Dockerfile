FROM node:22-slim
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev
COPY server ./server
COPY public ./public
ENV NODE_ENV=production PORT=5000 DATA_DIR=/data
VOLUME /data
EXPOSE 5000
CMD ["node", "server/index.js"]
