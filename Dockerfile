FROM ghcr.io/unkeyed/unkey:v2.0.49
COPY unkey.toml /unkey.toml
EXPOSE 7070
CMD ["run", "api"]