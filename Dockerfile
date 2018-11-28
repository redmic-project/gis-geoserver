FROM sgrio/java-oracle:jdk_8 AS build_apr

ENV APR_VERSION="1.6.5" \
	TOMCAT_NATIVE_VERSION="1.2.18" \
	TEMP_PATH="/tmp/resources"

RUN apt-get update && \
	apt-get install -y --no-install-recommends \
		build-essential \
		openssl \
		libssl-dev \
		curl && \
	rm -rf /var/lib/apt/lists/* && \
	mkdir -p "${TEMP_PATH}" && \
	#
	# Install APR
	#
	APR_FILENAME="apr-${APR_VERSION}.tar.gz" && \
	URL="http://www.us.apache.org/dist/apr/${APR_FILENAME}" && \
	curl -L ${URL} --output ${TEMP_PATH}/${APR_FILENAME} && \
	tar xvfz "${TEMP_PATH}/${APR_FILENAME}" -C ${TEMP_PATH} && \
	ls -la ${TEMP_PATH} && \
	cd "${TEMP_PATH}/apr-${APR_VERSION}" && \
	./configure --prefix=/usr/local/apr && \
	make && \
	make install && \
	#
	# Install Tomcat native
	#
	FILENAME="tomcat-native-${TOMCAT_NATIVE_VERSION}-src.tar.gz" && \
	URL="https://archive.apache.org/dist/tomcat/tomcat-connectors/native/${TOMCAT_NATIVE_VERSION}/source/${FILENAME}" && \
	curl -L ${URL} --output ${TEMP_PATH}/${FILENAME} && \
	tar xvfz ${TEMP_PATH}/${FILENAME} -C ${TEMP_PATH} && \
	cd "${TEMP_PATH}/tomcat-native-${TOMCAT_NATIVE_VERSION}-src/native" && \
	./configure --with-apr=/usr/local/apr && \
	make && \
	make install


FROM sgrio/java-oracle:jre_8

LABEL maintainer="info@redmic.es"

ENV MARLIN_VERSION="0.9.3" \
	TOMCAT_MAJOR="8" \
	TOMCAT_VERSION="8.5.35" \
	JAI_VERSION="1_1_3" \
	IMAGE_IO_VERSION="1_1" \
	GDAL_VERSION="2.2.3" \
	TURBO_JPEG_VERSION="1.5.3" \
	GEOSERVER_MAJOR_VERSION="2.14" \
	GEOSERVER_MINOR_VERSION="1" \
	CATALINA_HOME="/usr/local/tomcat"

ENV GEOSERVER_HOME="${CATALINA_HOME}/webapps/geoserver"

ENV GEOSERVER_PLUGINS="css inspire libjpeg-turbo csw wps pyramid vectortiles netcdf gdal netcdf-out" \
	GEOSERVER_COMMUNITY_PLUGINS="" \
	GEOSERVER_VERSION="${GEOSERVER_MAJOR_VERSION}.${GEOSERVER_MINOR_VERSION}" \
	GEOSERVER_DATA_DIR="/var/geoserver/data" \
	GEOSERVER_LOG_DIR="/var/log/geoserver" \
	GEOSERVER_LOG_LOCATION="${GEOSERVER_LOG_DIR}/geoserver.log" \
	GEOSERVER_OPTS="-Djava.awt.headless=true \
		-server \
		-XX:PerfDataSamplingInterval=500 \
		-Dorg.geotools.referencing.forceXY=true \
		-XX:SoftRefLRUPolicyMSPerMB=36000  \
		-XX:NewRatio=2 \
		-XX:+CMSClassUnloadingEnabled \
		-Djavax.servlet.request.encoding=UTF-8 \
		-Djavax.servlet.response.encoding=UTF-8 \
		-Dorg.geotools.shapefile.datetime=true \
		-XX:+UnlockExperimentalVMOptions \
		-XX:+AggressiveOpts \
		-XX:+UseCGroupMemoryLimitForHeap \
		-Xbootclasspath/a:${GEOSERVER_HOME}/WEB-INF/lib/marlin-${MARLIN_VERSION}-Unsafe.jar \
		-Dsun.java2d.renderer=org.marlin.pisces.MarlinRenderingEngine \
		-Djava.library.path=/usr/share/java:/opt/libjpeg-turbo/lib64:/usr/lib/jni:/usr/local/apr/lib:/usr/lib" \
	GEOSERVER_PORT="8080" \
	GOOGLE_FONTS="Open%20Sans Roboto Lato Ubuntu" \
	NOTO_FONTS="NotoSans-unhinted NotoSerif-unhinted NotoMono-hinted" \
	GDAL_DATA="/usr/share/gdal/2.2" \
	TEMP_PATH="/tmp/resources" \
	JRE_HOME="" \
	PATH="${CATALINA_HOME}/bin:${PATH}"

COPY ./scripts /

RUN mkdir -p "${TEMP_PATH}" "${GEOSERVER_DATA_DIR}" "${GEOSERVER_LOG_DIR}" "${CATALINA_HOME}" && \
	cd ${CATALINA_HOME} && \
	apt-get update && \
	apt-get install -y --no-install-recommends \
		fonts-cantarell \
		fonts-lyx \
		openssl \
		unzip \
		libtcnative-1 \
		libgdal-java \
		libgdal20 \
		libnetcdf13 \
		libnetcdf-c++4 \
		netcdf-bin \
		dnsutils \
		locales && \
	#
	# Install Google Noto fonts
	#
	mkdir -p /usr/share/fonts/truetype/noto && \
	for FONT in ${NOTO_FONTS}; \
	do \
		curl -L https://noto-website-2.storage.googleapis.com/pkgs/${FONT}.zip --output ${TEMP_PATH}/${FONT}.zip && \
		unzip -o ${TEMP_PATH}/${FONT}.zip -d /usr/share/fonts/truetype/noto ; \
	done && \
	#
	# Install Google Fonts
	#
	for FONT in ${GOOGLE_FONTS}; \
	do \
		mkdir -p /usr/share/fonts/truetype/${FONT} && \
		curl -L "https://fonts.google.com/download?family=${FONT}" --output ${TEMP_PATH}/${FONT}.zip && \
		unzip -o ${TEMP_PATH}/${FONT}.zip -d /usr/share/fonts/truetype/${FONT} ; \
	done && \
	#
	# Install Tomcat
	#
	URL="https://www.apache.org/dist/tomcat/tomcat-$TOMCAT_MAJOR/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.tar.gz" && \
	curl -fSL "${URL}" -o tomcat.tar.gz && \
	if ! tar -xvf tomcat.tar.gz --strip-components=1 ; \
	then \
		exit 1; \
	fi; \
	rm bin/*.bat && \
	rm tomcat.tar.gz* && \
	rm -rf ${CATALINA_HOME}/webapps/* && \
	#
	# Install GeoServer
	#
	FILENAME="geoserver-${GEOSERVER_VERSION}-war.zip" && \
	URL="https://sourceforge.net/projects/geoserver/files/GeoServer/${GEOSERVER_VERSION}" && \
	curl -L ${URL}/${FILENAME} -o ${TEMP_PATH}/${FILENAME} && \
	if ! unzip -o ${TEMP_PATH}/${FILENAME} -d ${TEMP_PATH} ; \
	then \
		echo "Download failed - Filename: ${FILENAME}" && \
		cat "${TEMP_PATH}/${FILENAME}" && \
		exit 1; \
	fi; \
	unzip -o ${TEMP_PATH}/geoserver.war -d ${GEOSERVER_HOME} && \
	mv /context.xml ${GEOSERVER_HOME}/META-INF/context.xml && \
	rm -rf ${GEOSERVER_HOME}/data/coverages/* \
		${GEOSERVER_HOME}/data/data/* \
		${GEOSERVER_HOME}/data/demo/* \
		${GEOSERVER_HOME}/data/gwc-layers/* \
		${GEOSERVER_HOME}/data/layergroups/* \
		${GEOSERVER_HOME}/data/workspaces/* && \
	#
	# Install Marlin
	#
	FILENAME=$(echo "marlin-${MARLIN_VERSION}-Unsafe.jar") && \
	MARLIN_VERSION_DASH=$(echo "v${MARLIN_VERSION}" | tr "." "_") && \
	URL="https://github.com/bourgesl/marlin-renderer/releases/download/${MARLIN_VERSION_DASH}/${FILENAME}" && \
	curl -L ${URL} --output ${TEMP_PATH}/${FILENAME} && \
	cp ${TEMP_PATH}/${FILENAME} ${GEOSERVER_HOME}/WEB-INF/lib && \
	#
	# Install Turbo JPEG
	#
	TURBO_JPEG_FILENAME=$(echo "libjpeg-turbo-official_${TURBO_JPEG_VERSION}_amd64.deb") && \
	URL="https://sourceforge.net/projects/libjpeg-turbo/files/${TURBO_JPEG_VERSION}/${TURBO_JPEG_FILENAME}" && \
	curl -L ${URL} --output ${TEMP_PATH}/${TURBO_JPEG_FILENAME} && \
	if ! dpkg -i ${TEMP_PATH}/${TURBO_JPEG_FILENAME} ; \
	then \
		echo "Download failed - Filename: ${TURBO_JPEG_FILENAME}" && \
		cat "${TEMP_PATH}/${TURBO_JPEG_FILENAME}" && \
		exit 1; \
	fi; \
	#
	# Install JAI
	#
	rm ${GEOSERVER_HOME}/WEB-INF/lib/jai_*jar && \
	JAI_FILENAME=$(echo "jai-${JAI_VERSION}-lib-linux-amd64.tar.gz") && \
	URL="http://download.java.net/media/jai/builds/release/${JAI_VERSION}/${JAI_FILENAME}" && \
	curl -L ${URL} --output ${TEMP_PATH}/${JAI_FILENAME} && \
	if ! tar xvfz ${TEMP_PATH}/${JAI_FILENAME} -C ${TEMP_PATH} ; \
	then \
		echo "Download failed - Filename: ${JAI_FILENAME}" && \
		cat "${TEMP_PATH}/${JAI_FILENAME}" && \
		exit 1; \
	fi; \
	mv ${TEMP_PATH}/jai-${JAI_VERSION}/lib/*.jar ${JAVA_HOME}/lib/ext/ && \
	mv ${TEMP_PATH}/jai-${JAI_VERSION}/lib/*.so ${JAVA_HOME}/lib/amd64/ && \
	#
	# Install Image IO
	#
	IMAGE_IO_FILENAME="jai_imageio-${IMAGE_IO_VERSION}-lib-linux-amd64.tar.gz" && \
	URL="http://download.java.net/media/jai-imageio/builds/release/1.1/${IMAGE_IO_FILENAME}" && \
	curl -L ${URL} --output ${TEMP_PATH}/${IMAGE_IO_FILENAME} && \
	if ! tar xvfz ${TEMP_PATH}/${IMAGE_IO_FILENAME} -C ${TEMP_PATH} ; \
	then \
		echo "Download failed - Filename: ${IMAGE_IO_FILENAME}" && \
		cat "${TEMP_PATH}/${IMAGE_IO_FILENAME}" && \
		exit 1; \
	fi; \
	mv ${TEMP_PATH}/jai_imageio-${IMAGE_IO_VERSION}/lib/*.jar ${JAVA_HOME}/lib/ext/ && \
	mv ${TEMP_PATH}/jai_imageio-${IMAGE_IO_VERSION}/lib/*.so ${JAVA_HOME}/lib/amd64/ && \
	#
	# Install GeoServer Plugins
	#
	URL="https://sourceforge.net/projects/geoserver/files/GeoServer/${GEOSERVER_VERSION}/extensions" && \
	for PLUGIN in ${GEOSERVER_PLUGINS}; \
	do \
		FILENAME="geoserver-${GEOSERVER_VERSION}-${PLUGIN}-plugin.zip" && \
		curl -L "${URL}/${FILENAME}" -o "${TEMP_PATH}/${FILENAME}" && \
		if ! unzip -o "${TEMP_PATH}/${FILENAME}" -d "${GEOSERVER_HOME}/WEB-INF/lib/" ; \
		then \
			echo "Download failed - Filename: ${FILENAME}" && \
			cat "${TEMP_PATH}/${FILENAME}" && \
			exit 1; \
		fi; \
	done && \
	#
	# Install GeoServer Community Plugins
	#
	URL="http://ares.opengeo.org/geoserver/master/community-latest/" && \
	for PLUGIN in ${GEOSERVER_COMMUNITY_PLUGINS}; \
	do \
		FILENAME="geoserver-${GEOSERVER_MAJOR_VERSION}-SNAPSHOT-${PLUGIN}-plugin.zip" && \
		curl -L ${URL}/${FILENAME} -o ${TEMP_PATH}/${FILENAME} && \
		if ! unzip -o "${TEMP_PATH}/${FILENAME}" -d "${GEOSERVER_HOME}/WEB-INF/lib/" ; \
		then \
			echo "Download failed - Filename: ${FILENAME}" && \
			cat "${TEMP_PATH}/${FILENAME}" && \
			exit 1; \
		fi; \
	done && \
	rm ${GEOSERVER_HOME}/WEB-INF/lib/imageio-ext-gdal-bindings-*.jar && \
	ln -s /usr/share/java/gdal.jar \
		"${GEOSERVER_HOME}/WEB-INF/lib/imageio-ext-gdal-bindings-${GDAL_VERSION}.jar" && \
	#
	# Install strong cryptography
	#
	mv /libs/*.jar ${JAVA_HOME}/lib/security/ && \
	#
	# Install locale
	sed -i -e 's/# es_ES.UTF-8 UTF-8/es_ES.UTF-8 UTF-8/' /etc/locale.gen && \
    locale-gen && \
	#
	#
	# Clean
	#
	rm -rf ${TEMP_PATH} && \
	rm /usr/share/doc/fonts-* && \
	rm -rf /var/lib/apt/lists/*

ENV LANG="es_ES.utf8"

EXPOSE ${GEOSERVER_PORT}

COPY --from=build_apr /usr/local/apr/lib /usr/local/apr/lib

WORKDIR ${CATALINA_HOME}

ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["catalina.sh", "run"]
