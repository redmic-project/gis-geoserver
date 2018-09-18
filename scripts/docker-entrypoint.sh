#!/bin/bash

sleep 15

if [ -z "$(ls -A ${GEOSERVER_DATA_DIR})" ]
then
    mkdir -p ${GEOSERVER_DATA_DIR}/coverages
    mkdir -p ${GEOSERVER_DATA_DIR}/data
    mkdir -p ${GEOSERVER_DATA_DIR}/gwc-layers
    mkdir -p ${GEOSERVER_DATA_DIR}/layergroups
    mkdir -p ${GEOSERVER_DATA_DIR}/workspaces

	echo "${GEOSERVER_HOME}"
	cp -arv "${GEOSERVER_HOME}/data_dir/"* "${GEOSERVER_DATA_DIR}"

	echo "Delete data_dir in container"
	rm -rf "${GEOSERVER_HOME}/data_dir"
fi

export JAVA_OPTS="${JAVA_OPTS} ${GEOSERVER_OPTS} -DGEOSERVER_LOG_LOCATION=${GEOSERVER_LOG_LOCATION}"

if [ "${ROLE}" == "master" ]
then
	/manage-slaves.sh & disown
fi

exec "$@"
