#!/bin/bash

set -e

if [ -z "$(ls -A ${GEOSERVER_DATA_DIR})" ]
then
	echo "Data dir is empty, creating data folders structure"
	mkdir -p ${GEOSERVER_DATA_DIR}/coverages ${GEOSERVER_DATA_DIR}/data ${GEOSERVER_DATA_DIR}/gwc-layers \
		${GEOSERVER_DATA_DIR}/layergroups ${GEOSERVER_DATA_DIR}/workspaces

	cp -arv "${GEOSERVER_HOME}/data_dir/"* "${GEOSERVER_DATA_DIR}"

  	echo "Delete data_dir in container"
	rm -rf "${GEOSERVER_HOME}/data_dir"
fi

echo "Discovering other nodes in cluster..."
serviceNodesIps=$(dig ${CLUSTER_DISCOVERY_URL} +short)
echo "${serviceNodesIps}"

myIp=$(dig ${HOSTNAME} +short)
echo "My IP: ${myIp}"

for nodeIp in ${serviceNodesIps}
do
	if [ "${nodeIp}" == "${myIp}" ];then
		continue;
	fi
	clusterNodesIps="${clusterNodesIps}<hostname>${nodeIp}</hostname>"
done
export CLUSTER_NODES_IPS_TAGS="${clusterNodesIps}"

mkdir -p ${GEOSERVER_DATA_DIR}/cluster

clusterTemplateName="cluster"
hazelcastTemplateName="hazelcast"

envsubst < /${clusterTemplateName}.template > ${GEOSERVER_DATA_DIR}/cluster/${clusterTemplateName}.properties
envsubst < /${hazelcastTemplateName}.template > ${GEOSERVER_DATA_DIR}/cluster/${hazelcastTemplateName}.properties

export JAVA_OPTS="${JAVA_OPTS} ${GEOSERVER_OPTS} -DGEOSERVER_LOG_LOCATION=${GEOSERVER_LOG_LOCATION}"

exec "$@"
