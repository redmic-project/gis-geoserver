#!/bin/bash

if [ -z "$(ls -A ${GEOSERVER_DATA_DIR})" ]
then
	echo "Move data_dir"

	mv -v "${GEOSERVER_HOME}/data_dir/"* "${GEOSERVER_DATA_DIR}/"
fi

export JAVA_OPTS="${JAVA_OPTS} ${GEOSERVER_OPTS} -DGEOSERVER_LOG_LOCATION=${GEOSERVER_LOG_LOCATION}"

if [ "${ROLE}" == "master" ]
then
	/manage-slaves.sh & disown
fi

exec "$@"
