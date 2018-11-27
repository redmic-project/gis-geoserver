#!/bin/bash

if [ -z "$(ls -A ${GEOSERVER_DATA_DIR})" ]
then
	echo "Move data from ${GEOSERVER_HOME}/data/ to ${GEOSERVER_DATA_DIR}/"
	mkdir -p "${GEOSERVER_DATA_DIR}/logs"
	mv /*LOGGING.properties "${GEOSERVER_DATA_DIR}/logs/DEFAULT_LOGGING.properties"
	ls -la "${GEOSERVER_DATA_DIR}/logs"
	mv "${GEOSERVER_HOME}/data/"* "${GEOSERVER_DATA_DIR}/"
fi

export JAVA_OPTS="${JAVA_OPTS} ${GEOSERVER_OPTS} -DGEOSERVER_LOG_LOCATION=${GEOSERVER_LOG_LOCATION}"

if [ "${ROLE}" == "master" ]
then
	/manage-slaves.sh & disown
fi

exec "$@"
