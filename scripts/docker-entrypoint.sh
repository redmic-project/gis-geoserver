#!/bin/bash

if [ -z "$(ls -A ${GEOSERVER_DATA_DIR})" ]
then
	echo "Copy data_dir"
	mv "${GEOSERVER_HOME}/data_dir/"* "${GEOSERVER_DATA_DIR}/"
	rm -rf ${GEOSERVER_DATA_DIR}/workspaces/*
	rm -rf ${GEOSERVER_DATA_DIR}/layergroups/*
	rm -rf ${GEOSERVER_DATA_DIR}/data/*
	rm -rf ${GEOSERVER_DATA_DIR}/coverages/*
fi

export JAVA_OPTS="${JAVA_OPTS} ${GEOSERVER_OPTS} -DGEOSERVER_LOG_LOCATION=${GEOSERVER_LOG_LOCATION}"

if [ "${ROLE}" == "master" ]
then
	/manage-slaves.sh & disown
fi

exec "$@"
