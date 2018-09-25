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

/discovery.sh & disown

exec "$@"
