#!/bin/bash

set -e

if [ -z "$(ls -A ${GEOSERVER_DATA_DIR})" ]
then
	echo "Data dir is empty, creating data folders structure"
    mkdir -p ${GEOSERVER_DATA_DIR}/coverages
    mkdir -p ${GEOSERVER_DATA_DIR}/data
    mkdir -p ${GEOSERVER_DATA_DIR}/gwc-layers
    mkdir -p ${GEOSERVER_DATA_DIR}/layergroups
    mkdir -p ${GEOSERVER_DATA_DIR}/workspaces

    cp -arv "${GEOSERVER_HOME}/data_dir/"* "${GEOSERVER_DATA_DIR}"

  	echo "Delete data_dir in container"
	rm -rf "${GEOSERVER_HOME}/data_dir"
fi

if [ ! -d "${GEOSERVER_DATA_DIR}" ]
then
    mkdir -p ${GEOSERVER_DATA_DIR}/cluster

    clusterTemplateFilename="cluster"
    hazelcastTemplateFilename="hazelcast"

    envsubst < /${clusterTemplateFilename}.template > ${GEOSERVER_DATA_DIR}/cluster/${clusterTemplateFilename}.properties
    envsubst < /${hazelcastTemplateFilename}.template > ${GEOSERVER_DATA_DIR}/cluster/${hazelcastTemplateFilename}.properties
fi

export JAVA_OPTS="${JAVA_OPTS} ${GEOSERVER_OPTS} -DGEOSERVER_LOG_LOCATION=${GEOSERVER_LOG_LOCATION}"

exec "$@"
