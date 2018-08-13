#!/bin/bash

set -e

if [ -z "$(ls -A ${GEOSERVER_DATA_DIR})" ]
then
	echo "Copy data_dir"
	cp -r "${GEOSERVER_HOME}/data_dir/*" "${GEOSERVER_DATA_DIR}"
fi

exec "$@"
