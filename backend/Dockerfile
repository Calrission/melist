# Build context is the repository root (see docker-compose.yml).
# Frontend is omitted: it needs the Flutter SDK, the API does not.
FROM dart:stable AS build

WORKDIR /workspace

COPY core ./core
COPY backend ./backend

RUN printf '%s\n' \
    'name: melist_workspace' \
    'publish_to: none' \
    'environment:' \
    '  sdk: ^3.12.0' \
    'workspace:' \
    '  - core' \
    '  - backend' \
    > pubspec.yaml

WORKDIR /workspace/backend
RUN dart pub get
RUN dart pub global activate dart_frog_cli
ENV PATH="/root/.pub-cache/bin:${PATH}"
RUN dart_frog build
RUN dart run dart_frog_swagger
RUN dart run tool/patch_openapi.dart

WORKDIR /workspace/backend/build
RUN dart pub get
RUN dart compile exe bin/server.dart -o /server

FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /server /bin/server
COPY --from=build /workspace/backend/build/openapi.json \
    /app/build/openapi.json
COPY --from=build /workspace/backend/pubspec.yaml \
    /app/pubspec.yaml
WORKDIR /app
ENV PORT=8080
EXPOSE 8080
CMD ["/bin/server"]
