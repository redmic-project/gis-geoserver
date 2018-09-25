#!/bin/bash

sleep 10

echo "Discovering other nodes in cluster..."
serviceNodesIps=$(dig ${CLUSTER_DISCOVERY_URL} +short)
echo "${serviceNodesIps}"

myIp=$(dig ${HOSTNAME} +short)
echo "My hostname: ${HOSTNAME}"
echo "My IP: ${myIp}"
export MY_IP="${myIp}"

for nodeIp in ${serviceNodesIps}
do
	clusterNodesIps="${clusterNodesIps}<member>${nodeIp}</member>"
done
export CLUSTER_NODES_IPS_TAGS="${clusterNodesIps}"

export HAZELCAST_OUTBOUND_PORTS_RANGE=$((${HAZELCAST_PORT} + 101))-$((${HAZELCAST_PORT} + 201))

clusterDir="${GEOSERVER_DATA_DIR}/cluster-${myIp}"
clusterTemplateName="cluster"
hazelcastTemplateName="hazelcast"

mkdir -p ${clusterDir}

envsubst < /${clusterTemplateName}.template > ${clusterDir}/${clusterTemplateName}.properties
envsubst < /${hazelcastTemplateName}.template > ${clusterDir}/${hazelcastTemplateName}.xml

export JAVA_OPTS="${JAVA_OPTS} ${GEOSERVER_OPTS} \
	-DGEOSERVER_LOG_LOCATION=${GEOSERVER_LOG_LOCATION} \
	-Dhazelcast.config.dir=${clusterDir}"
