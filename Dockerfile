FROM openweb/oracle-tomcat:8.5-jre8

LABEL maintainer="info@redmic.es"

ENV DEBIAN_FRONTEND="noninteractive" \
	GEOSERVER_PLUGINS="css inspire libjpeg-turbo csw wps pyramid vectortiles netcdf gdal importer netcdf-out" \
	GEOSERVER_COMMUNITY_PLUGINS="" \
	GEOSERVER_MAJOR_VERSION="2.13" \
	GEOSERVER_MINOR_VERSION="3" \
	GEOSERVER_DATA_DIR="/var/geoserver/data" \
	GEOSERVER_HOME="${CATALINA_HOME}/webapps/geoserver" \
	GEOSERVER_LOG_DIR="/var/log/geoserver" \
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
		-Djava.library.path=/usr/share/java:/opt/libjpeg-turbo/lib64:/usr/lib/jni" \
	GOOGLE_FONTS="Open%20Sans Roboto Lato Ubuntu" \
	NOTO_FONTS="NotoSans-unhinted NotoSerif-unhinted NotoMono-hinted" \
	GEOSERVER_PORT="8080"

ENV GEOSERVER_VERSION="${GEOSERVER_MAJOR_VERSION}.${GEOSERVER_MINOR_VERSION}" \
	GEOSERVER_LOG_LOCATION="${GEOSERVER_LOG_DIR}/geoserver.log" \
	GDAL_DATA="/usr/share/gdal/2.1"

# El espacio final es necesario, corrige bug en script de arranque
ENV MARLIN_JAR="${GEOSERVER_HOME}/lib/marlin-${MARLIN_VERSION}-Unsafe.jar "
ARG TURBO_JPEG_VERSION=1.5.3
ARG TEMP_PATH=/tmp/resources
ARG MARLIN_VERSION=0.9.3
ARG JAI_VERSION=1_1_3
ARG IMAGE_IO_VERSION=1_1
ARG GDAL_VERSION="2.1.2"

COPY ./scripts /

# Install extra fonts to use with sld font markers
RUN mkdir -p "${TEMP_PATH}" "${GEOSERVER_DATA_DIR}" "${GEOSERVER_LOG_DIR}" && \
	apt-get update && \
	apt-get install -y --no-install-recommends fonts-cantarell \
#		lmodern \
#		ttf-aenigma \
#		ttf-georgewilliams \
#		ttf-bitstream-vera \
#		ttf-sjfonts \
#		tv-fonts \
#		fonts-lyx \
		unzip \
		libtcnative-1 \
#		libgdal20 \
		libgdal-java \
		libnetcdf11 \
		libnetcdf-c++4 \
		netcdf-bin \
		dnsutils && \
	# Copy resources
	# Install Google Noto fonts
	mkdir -p /usr/share/fonts/truetype/noto && \
	for FONT in ${NOTO_FONTS}; \
	do \
		curl -L https://noto-website-2.storage.googleapis.com/pkgs/${FONT}.zip --output ${TEMP_PATH}/${FONT}.zip && \
		unzip -o ${TEMP_PATH}/${FONT}.zip -d /usr/share/fonts/truetype/noto ; \
	done && \
	# Install Google Fonts
	for FONT in ${GOOGLE_FONTS}; \
	do \
		mkdir -p /usr/share/fonts/truetype/${FONT} && \
		curl -L "https://fonts.google.com/download?family=${FONT}" --output ${TEMP_PATH}/${FONT}.zip && \
		unzip -o ${TEMP_PATH}/${FONT}.zip -d /usr/share/fonts/truetype/${FONT} ; \
	done && \
	# Clean Tomcat
	rm -rf ${CATALINA_HOME}/webapps/* && \
	# Install GeoServer
	FILENAME="geoserver-${GEOSERVER_VERSION}-war.zip" && \
	URL="https://sourceforge.net/projects/geoserver/files/GeoServer/${GEOSERVER_VERSION}" && \
	curl -L ${URL}/${FILENAME} -o ${TEMP_PATH}/${FILENAME} && \
	unzip -o ${TEMP_PATH}/${FILENAME} -d ${TEMP_PATH} && \
	unzip -o ${TEMP_PATH}/geoserver.war -d ${GEOSERVER_HOME} && \
	mv /context.xml ${GEOSERVER_HOME}/META-INF/context.xml && \
	rm -rf ${GEOSERVER_HOME}/data/coverages/* \
		${GEOSERVER_HOME}/data/data/* \
		${GEOSERVER_HOME}/data/demo/* \
		${GEOSERVER_HOME}/data/gwc-layers/* \
		${GEOSERVER_HOME}/data/layergroups/* \
		${GEOSERVER_HOME}/data/workspaces/* && \
	# Install Marlin
	FILENAME=$(echo "marlin-${MARLIN_VERSION}-Unsafe.jar") && \
	URL="https://github.com/bourgesl/marlin-renderer/releases/download/v0_9_1//${FILENAME}" && \
	curl -L ${URL} --output ${TEMP_PATH}/${FILENAME} && \
	cp ${TEMP_PATH}/${FILENAME} ${GEOSERVER_HOME}/lib && \
	# Install Turbo JPEG
	TURBO_JPEG_FILENAME=$(echo "libjpeg-turbo-official_${TURBO_JPEG_VERSION}_amd64.deb") && \
	URL="https://sourceforge.net/projects/libjpeg-turbo/files/${TURBO_JPEG_VERSION}/${TURBO_JPEG_FILENAME}" && \
	curl -L ${URL} --output ${TEMP_PATH}/${TURBO_JPEG_FILENAME} && \
	dpkg -i ${TEMP_PATH}/${TURBO_JPEG_FILENAME} && \
	# Install JAI & Image IO
	rm ${GEOSERVER_HOME}/WEB-INF/lib/jai_*jar && \
	JAI_FILENAME=$(echo "jai-${JAI_VERSION}-lib-linux-amd64.tar.gz") && \
	URL="http://download.java.net/media/jai/builds/release/${JAI_VERSION}/${JAI_FILENAME}" && \
	curl -L ${URL} --output ${TEMP_PATH}/${JAI_FILENAME} && \
	tar xvfz ${TEMP_PATH}/${JAI_FILENAME} -C ${TEMP_PATH} && \
	mv ${TEMP_PATH}/jai-${JAI_VERSION}/lib/*.jar ${JAVA_HOME}/lib/ext/ && \
	mv ${TEMP_PATH}/jai-${JAI_VERSION}/lib/*.so ${JAVA_HOME}/lib/amd64/ && \
	IMAGE_IO_FILENAME="jai_imageio-${IMAGE_IO_VERSION}-lib-linux-amd64.tar.gz" && \
	URL="http://download.java.net/media/jai-imageio/builds/release/1.1/${IMAGE_IO_FILENAME}" && \
	curl -L ${URL} --output ${TEMP_PATH}/${IMAGE_IO_FILENAME} && \
	tar xvfz ${TEMP_PATH}/${IMAGE_IO_FILENAME} -C ${TEMP_PATH} && \
	mv ${TEMP_PATH}/jai_imageio-${IMAGE_IO_VERSION}/lib/*.jar ${JAVA_HOME}/lib/ext/ && \
	mv ${TEMP_PATH}/jai_imageio-${IMAGE_IO_VERSION}/lib/*.so ${JAVA_HOME}/lib/amd64/ && \
	# Install GeoServer Plugins
	URL="https://sourceforge.net/projects/geoserver/files/GeoServer/${GEOSERVER_VERSION}/extensions" && \
	for PLUGIN in ${GEOSERVER_PLUGINS}; \
	do \
		FILENAME="geoserver-${GEOSERVER_VERSION}-${PLUGIN}-plugin.zip" && \
		curl -L "${URL}/${FILENAME}" -o "${TEMP_PATH}/${FILENAME}" && \
		unzip -o "${TEMP_PATH}/${FILENAME}" -d "${GEOSERVER_HOME}/WEB-INF/lib/" ; \
	done && \
	# Install GeoServer Community Plugins
	URL="http://ares.opengeo.org/geoserver/master/community-latest/" && \
	for PLUGIN in ${GEOSERVER_COMMUNITY_PLUGINS}; \
	do \
		FILENAME="geoserver-${GEOSERVER_MAJOR_VERSION}-SNAPSHOT-${PLUGIN}-plugin.zip" && \
		curl -L ${URL}/${FILENAME} -o ${TEMP_PATH}/${FILENAME} && \
		unzip -o ${TEMP_PATH}/${FILENAME} -d ${GEOSERVER_HOME}/WEB-INF/lib/ ; \
	done && \
	rm ${GEOSERVER_HOME}/WEB-INF/lib/imageio-ext-gdal-bindings-*.jar && \
	ln -s /usr/share/java/gdal.jar \
		"${GEOSERVER_HOME}/WEB-INF/lib/imageio-ext-gdal-bindings-${GDAL_VERSION}.jar" && \
	# Clean
	rm -fr ${TEMP_PATH} && \
	rm -rf /var/lib/apt/lists/* && \
	apt-get clean

EXPOSE ${GEOSERVER_PORT}

RUN mv /libs/*.jar ${JAVA_HOME}/lib/security/

ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["catalina.sh", "run"]