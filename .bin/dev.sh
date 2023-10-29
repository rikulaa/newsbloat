#!/bin/sh
killall postgres; pg_ctl -l "$PGDATA/server.log" start
# Shutdown db on exit as well
trap "killall postgres" EXIT
iex -S mix phx.server
