# https://staknine.com/build-an-elixir-release-with-docker-to-deploy-anywhere/
FROM elixir:1.12.3-alpine as build

# install build dependencies
RUN apk add --update git build-base nodejs npm yarn python3

RUN mkdir /app
WORKDIR /app

# install Hex + Rebar
RUN mix do local.hex --force, local.rebar --force

# set build ENV
ENV MIX_ENV=prod
COPY .env /app

# install mix dependencies
COPY mix.exs mix.lock ./
COPY config config
RUN . .env && mix deps.get --only prod
RUN . .env && MIX_ENV=prod mix deps.compile

# build assets
COPY assets assets
RUN cd assets && npm install && NODE_ENV=production npm run deploy
RUN . .env && mix phx.digest

# build project
COPY priv priv
COPY lib lib
RUN . .env && MIX_ENV=prod mix compile

# build release
# at this point we should copy the rel directory but
# we are not using it so we can omit it
# COPY rel rel
RUN . .env && MIX_ENV=prod mix release

# prepare release image
FROM alpine:3.14.2 AS app

# install runtime dependencies
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
