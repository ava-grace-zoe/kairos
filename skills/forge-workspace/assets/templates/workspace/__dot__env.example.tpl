# 仅供本地开发；生产环境通过部署平台注入独立凭据。
DATABASE_URL=postgresql://forge:forge_local@127.0.0.1:54329/__WORKSPACE__?schema=public
POSTGRES_PORT=54329
# 浏览器由开发代理调用后端，后端不需要开放跨域。
VITE_API_TARGET=http://127.0.0.1:3000
