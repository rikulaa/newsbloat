#!/bin/sh

echo

if [ ! -d "deps" ] || [ ! "$(ls -A deps)" ]; then
    printf "\e[32m=> Fetching dependencies and building the application...\e[0m\n\n"
    echo "+ mix do deps.get, compile --verbose"
    mix do deps.get, compile --verbose
    echo
fi

if [ ! -d "$PGDATA" ]; then
    printf "\e[32m=> Initialising the database in $PGDATA...\e[0m\n\n"
    echo "+ initdb --no-locale --encoding=UTF-8"
    initdb --no-locale --encoding=UTF-8
    echo
fi

if [ ! -f "$PGDATA/postmaster.pid" ]; then
    printf "\e[32m=> Starting PostgreSQL...\e[0m\n\n"
    echo "+ pg_ctl -l \"$PGDATA/server.log\" start"
    pg_ctl -l "$PGDATA/server.log" start
    echo
fi

printf "\e[32m=> Creating the postgres user if necessary...\e[0m\n\n"
echo "+ createuser postgres --createdb --echo"
createuser postgres --createdb --echo
echo

set -e

printf "\e[32m=> Setting up the database...\e[0m\n\n"
echo "+ mix ecto.reset"
mix ecto.reset
echo

printf "\e[32m=> Stop PostgreSQL...\e[0m\n\n"
pg_ctl stop

printf "\e[32m\e[1mThe project setup is complete!\e[0m\n\n"
printf "To start the application in an IEx shell, you can now run:\n\n"
printf "    iex -S mix phx.server\n\n"
