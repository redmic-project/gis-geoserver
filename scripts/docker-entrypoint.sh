#!/bin/bash

set -e

FILENAME="cluster"

if [ -z "$(ls -A ${GEOSERVER_DATA_DIR})" ]
then
	echo "Copy data_dir"
	cp -r "${GEOSERVER_HOME}/data_dir/*" "${GEOSERVER_DATA_DIR}"
fi

if [ "${ROLE}" == "master-slave" ]
then
	export SLAVE_ACTIVE="true"
	export MASTER_ACTIVE="true"
elif [ "${ROLE}" == "master" ]
then
	export SLAVE_ACTIVE="false"
	export MASTER_ACTIVE="true"
else
	export SLAVE_ACTIVE="true"
	export MASTER_ACTIVE="false"
	# Deactivate web, this node is slave
	export JAVA_OPTS="${JAVA_OPTS} -DGEOSERVER_CONSOLE_DISABLED=true"
fi

envsubst < /${FILENAME}.template > ${CLUSTER_CONFIG_DIR}/${FILENAME}.properties

if [ -n "${DEBUG}"]
then
	cat ${CLUSTER_CONFIG_DIR}/${FILENAME}.properties
fi

exec "$@"
