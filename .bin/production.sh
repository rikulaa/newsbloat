#!/bin/sh
# Initial setup

git pull

# Source env-variables
. ./.env

mix deps.get --only prod

MIX_ENV=prod mix compile

# Compile assets

MIX_ENV=prod mix assets.deploy

# Custom tasks (like DB migrations)

MIX_ENV=prod mix ecto.migrate

 # Run tenant migrations
MIX_ENV=prod mix triplex.migrate

# assets
MIX_ENV=prod mix phx.digest

MIX_ENV=prod mix phx.server
