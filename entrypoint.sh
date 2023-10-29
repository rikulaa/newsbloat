#!/bin/sh

# Run migrations
_build/prod/rel/newsbloat/bin/newsbloat eval "Newsbloat.Release.migrate"
_build/prod/rel/newsbloat/bin/newsbloat start
