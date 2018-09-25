#!/bin/bash

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

for nodeIp in ${serviceNodesIps}
do
	clusterNodesIps="${clusterNodesIps}<member>${nodeIp}</member>"
done
export CLUSTER_NODES_IPS_TAGS="${clusterNodesIps}"

export HAZELCAST_OUTBOUND_PORTS_RANGE=$((${HAZELCAST_PORT} + 101))-$((${HAZELCAST_PORT} + 201))

mkdir -p ${GEOSERVER_DATA_DIR}/cluster

clusterTemplateName="cluster"
hazelcastTemplateName="hazelcast"

envsubst < /${clusterTemplateName}.template > ${GEOSERVER_DATA_DIR}/cluster/${clusterTemplateName}.properties
envsubst < /${hazelcastTemplateName}.template > ${GEOSERVER_DATA_DIR}/cluster/${hazelcastTemplateName}.xml

export JAVA_OPTS="${JAVA_OPTS} ${GEOSERVER_OPTS} -DGEOSERVER_LOG_LOCATION=${GEOSERVER_LOG_LOCATION}"

exec "$@"
