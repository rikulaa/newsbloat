# https://staknine.com/build-an-elixir-release-with-docker-to-deploy-anywhere/
FROM hexpm/elixir:1.12.3-erlang-24.3.4.13-alpine-3.17.5 AS build

# install build dependencies
RUN apk add --update git build-base nodejs npm yarn python3

RUN mkdir /app
WORKDIR /app

# install Hex + Rebar
RUN mix do local.hex --force, local.rebar --force

# set build ENV
ENV MIX_ENV=prod

# install mix dependencies
COPY mix.exs mix.lock ./
COPY config config
RUN mix deps.get --only prod
RUN mix deps.compile

COPY assets assets
COPY lib lib
COPY priv priv

# build assets
RUN npm --prefix ./assets ci --progress=false --no-audit --loglevel=error
RUN NODE_ENV=production NODE_OPTIONS=--openssl-legacy-provider npm run deploy --prefix ./assets
RUN mix phx.digest

# compile and build release
# uncomment COPY if rel/ exists
# COPY rel rel
RUN mix do compile, release

# ==============================================================
# Release
# ==============================================================

# prepare release image
# https://stackoverflow.com/questions/72609505/issue-with-building-elixir-and-beam-on-alpine-linux
# FROM alpine:3.14.2 AS app
# FROM hexpm/elixir:1.12.3-erlang-22.1.8.1-ubuntu-focal-20231003 AS app
FROM hexpm/elixir:1.12.3-erlang-24.3.4.13-alpine-3.17.5 AS app

# install runtime dependencies
# RUN apt-get update
RUN apk add --update bash openssl postgresql-client bash openssl libgcc libstdc++ ncurses-libs

EXPOSE 4000
ENV MIX_ENV=prod

# prepare app directory
RUN mkdir /app
WORKDIR /app

# copy release to app container
COPY --from=build /app/_build /app/_build
COPY .env .
COPY entrypoint.sh .

RUN chown -R nobody: /app
USER nobody

ENV HOME=/app
CMD ["bash", "/app/entrypoint.sh"]
