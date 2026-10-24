# Estágio 1: compilação
FROM dart:stable AS build
WORKDIR /app
COPY pubspec.* ./
RUN dart pub get
COPY . .
RUN dart pub get --offline
RUN dart compile exe bin/server.dart -o /app/bin/server

# Estágio 2: imagem final de execução
FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /app/bin/server /app/bin/server
WORKDIR /app
EXPOSE 3001
CMD ["/app/bin/server"]