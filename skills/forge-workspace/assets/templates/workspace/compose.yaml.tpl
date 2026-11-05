services:
  postgres:
    image: postgres:18.3-alpine
    environment:
      POSTGRES_USER: forge
      POSTGRES_PASSWORD: forge_local
      POSTGRES_DB: __WORKSPACE__
    ports:
      - "127.0.0.1:${POSTGRES_PORT:-54329}:5432"
    volumes:
      - postgres-data:/var/lib/postgresql
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U forge -d __WORKSPACE__"]
      interval: 2s
      timeout: 3s
      retries: 30
volumes:
  postgres-data:
