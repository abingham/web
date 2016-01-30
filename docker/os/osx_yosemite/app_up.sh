#!/bin/bash

# Brings up cyber-dojo in OSX Docker Quickstart Terminal.
# Assumes yml files are in their respective git repo folders.

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

pushd ${DIR}
docker-compose -f ../docker-compose.yml -f docker-compose.osx.yml up &
popd
