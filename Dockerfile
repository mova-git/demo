FROM node:20

WORKDIR /app

COPY package*.json ./

RUN npm install

# Copy only app files needed at runtime while excluding common sensitive paths.
COPY --chown=node:node . . --exclude=.git --exclude=node_modules --exclude=.env --exclude=.env.* --exclude=secrets

EXPOSE 3000

CMD ["npm", "start"]