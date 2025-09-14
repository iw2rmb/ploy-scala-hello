# syntax=docker/dockerfile:1

# Build stage: compile and prepare distribution using Gradle
FROM gradle:8.8-jdk-21 AS build
WORKDIR /src
COPY . .
RUN gradle --no-daemon clean installDist

# Runtime stage: slim JRE with app distribution
FROM eclipse-temurin:21-jre
ENV APP_HOME=/opt/app
WORKDIR ${APP_HOME}
# Copy full install tree (contains <project>/bin and /lib)
COPY --from=build /src/build/install /opt/install
# Expose default HTTP port
EXPOSE 8080
# Basic healthcheck hitting hello/health endpoint if present
HEALTHCHECK --interval=10s --timeout=5s --start-period=15s \
  CMD curl -fsS http://localhost:8080/healthz || curl -fsS http://localhost:8080/health || exit 1
# Execute the first discovered app launcher under /opt/install/*/bin/*
CMD ["bash","-lc","exec $(find /opt/install -maxdepth 2 -type f -path '*/bin/*' | head -n1)"]
