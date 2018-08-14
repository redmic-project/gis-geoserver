#!/bin/bash

if [ -z "$(ls -A ${GEOSERVER_DATA_DIR})" ]
then
	echo "Copy data_dir"
	cp -r "${GEOSERVER_HOME}/data_dir/*" "${GEOSERVER_DATA_DIR}"
fi

if [ "${ROLE}" == "master" ]
then
	/manage-slaves.sh & disown
fi

exec "$@"
