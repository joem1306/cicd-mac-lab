FROM node:22-alpine
WORKDIR /app
COPY package.json server.js version.json ./
USER node
EXPOSE 3000
CMD ["node", "server.js"]
