#!/bin/bash

set -e

FILENAME="cluster"

echo "Synchronizing ${GEOSERVER_DATA_DIR}"
rsync -vrt ${GEOSERVER_HOME}/data_dir ${GEOSERVER_DATA_DIR}

if [ -z ${BROKER_SERVICE_NAME} ]; then
    >&2 echo "Environment variable BROKER_SERVICE_NAME unset. You MUST set it to a service name."
    exit 3
fi

if [ -n "${SWARM_MODE}" ]; then
	SERVICE_PREFIX="tasks."
else
	SERVICE_PREFIX=""
fi

echo "Discovering service nodes..."
# Docker swarm's DNS resolves special hostname "tasks.<service_name" to IP addresses of all containers inside overlay network
SERVICE_NODES=$(dig ${SERVICE_PREFIX}${BROKER_SERVICE_NAME} +short)
echo "Nodes of service ${BROKER_SERVICE_NAME}:"
echo "${SERVICE_NODES}"

NODE_IPS=""
for NODE_IP in ${SERVICE_NODES}; do
	if [ -n "${NODE_IPS}" ]; then
		NODE_IPS="${NODE_IPS},"
	fi
	NODE_IPS="${NODE_IPS}tcp\://${NODE_IP}\:${ACTIVEMQ_PORT}"
done

export BROKER_URL="failover\:(${NODE_IPS})?jms.useAsyncSend\=true"

if [ ${ROLE} == "master" ]; then
	export SLAVE_ACTIVE="false"
	export MASTER_ACTIVE="true"
else
	export SLAVE_ACTIVE="true"
	export MASTER_ACTIVE="false"
	# Deactivate web, this node is slave
	export JAVA_OPTS="${JAVA_OPTS} -DGEOSERVER_CONSOLE_DISABLED=true"
fi

envsubst < /${FILENAME}.template > ${CLUSTER_CONFIG_DIR}/${FILENAME}.properties

if [ -n "${DEBUG}"]; then
	cat ${CLUSTER_CONFIG_DIR}/${FILENAME}.properties
fi

exec "$@"
