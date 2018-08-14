#!/bin/sh

if [ -n "${SWARM_MODE}" ]
then
	servicePrefix="tasks."
else
	servicePrefix=""
fi

sleep "${SLAVES_MANAGEMENT_DELAY}"

while :
do
	echo "Discovering slave instances..."
	nodeIps=$(dig ${servicePrefix}${SLAVE_SERVICE_NAME} +short)
	echo "Nodes of service ${SLAVE_SERVICE_NAME}:"
	echo "${nodeIps}"

	echo "Reloading slave instances..."
	for nodeIp in ${nodeIps}
	do
		echo "Reloading slave instance in ${nodeIp}..."
		curl -XPOST -u "${GEOSERVER_USER}:${GEOSERVER_PASS}" "${nodeIp}:${GEOSERVER_PORT}/geoserver/rest/reload"
		if [ "${?}" -eq "0" ]
		then
			sleep "${SLAVE_MANAGEMENT_TIMEOUT}"
		else
			echo "Failed to reload slave instance in ${nodeIp}"
		fi
	done

	echo "Slave instances reloaded"
	sleep "${SLAVES_MANAGEMENT_INTERVAL}"
done
