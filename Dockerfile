FROM openjdk:8-jdk

ENV DEBIAN_FRONTEND="noninteractive" \
    GEOSERVER_PLUGINS="css inspire libjpeg-turbo csw wps pyramid vectortiles netcdf gdal importer netcdf-out" \
    GEOSERVER_COMMUNITY_PLUGINS="gwc-s3" \
    GEOSERVER_MAJOR_VERSION="2.12" \
    GEOSERVER_MINOR_VERSION="2" \
    GEOSERVER_DATA_DIR="/var/geoserver/data" \
    GEOSERVER_HOME="/opt/geoserver" \
    GEOSERVER_LOG_LOCATION="/var/log" \
    GEOSERVER_OPTS="-server -Xrs -XX:PerfDataSamplingInterval=500 \
     -Dorg.geotools.referencing.forceXY=true -XX:SoftRefLRUPolicyMSPerMB=36000 \
     -XX:+UseParallelGC --XX:+UseParNewGC –XX:+UseG1GC -XX:NewRatio=2 \
     -XX:+CMSClassUnloadingEnabled" \
    GOOGLE_FONTS="Open%20Sans Roboto Lato Ubuntu" \
    NOTO_FONTS="NotoSans-unhinted NotoSerif-unhinted NotoMono-hinted"

ENV GEOSERVER_VERSION="${GEOSERVER_MAJOR_VERSION}.${GEOSERVER_MINOR_VERSION}" \
    GEOSERVER_LOG_LOCATION="${GEOSERVER_LOG_DIR}/geoserver.log" \
    GDAL_DATA="/usr/share/gdal/2.1" \
    JAVA_OPTS="${JAVA_OPTS} -Djava.library.path=/usr/share/java:/opt/libjpeg-turbo/lib64:/usr/lib/jni ${GEOSERVER_OPTS}"

ARG TEMP_PATH=/tmp/resources

RUN mkdir -p ${TEMP_PATH} ${GEOSERVER_DATA_DIR}

# Install extra fonts to use with sld font markers
RUN apt-get update && \
    apt-get install -y --no-install-recommends fonts-cantarell \
        lmodern \
        ttf-aenigma \
        ttf-georgewilliams \
        ttf-bitstream-vera \
        ttf-sjfonts \
        tv-fonts \
        libtcnative-1 \
        libgdal20 \
        libgdal-java \
        libnetcdf11 \
        libnetcdf-c++4 \
        netcdf-bin

# Copy resources
COPY resources ${TEMP_PATH}

# Install Google Noto fonts
RUN mkdir -p /usr/share/fonts/truetype/noto && \
    for FONT in ${NOTO_FONTS}; \
    do \
        if [ ! -f ${TEMP_PATH}/${FONT}.zip ]; then \
            curl -L https://noto-website-2.storage.googleapis.com/pkgs/${FONT}.zip --output ${TEMP_PATH}/${FONT}.zip ; \
        fi; \
        unzip -o ${TEMP_PATH}/${FONT}.zip -d /usr/share/fonts/truetype/noto ; \
    done

# Install Google Fonts
RUN for FONT in ${GOOGLE_FONTS}; \
    do \
        mkdir -p /usr/share/fonts/truetype/${FONT} && \
        if [ ! -f ${TEMP_PATH}/${FONT}.zip ]; then \
            curl -L "https://fonts.google.com/download?family=${FONT}" --output ${TEMP_PATH}/${FONT}.zip ; \
        fi; \
        unzip -o ${TEMP_PATH}/${FONT}.zip -d /usr/share/fonts/truetype/${FONT} ; \
    done

# Install GeoServer
RUN FILENAME="geoserver-${GEOSERVER_VERSION}-bin.zip" && \
    if [ ! -f ${TEMP_PATH}/${FILENAME} ]; then \
        URL="https://sourceforge.net/projects/geoserver/files/GeoServer/${GEOSERVER_VERSION}" && \
        curl -L ${URL}/${FILENAME} -o ${TEMP_PATH}/${FILENAME} ; \
    fi; \
    unzip -o ${TEMP_PATH}/${FILENAME} -d /opt/ && \
    mv -v ${GEOSERVER_HOME}* ${GEOSERVER_HOME} && \
    rm -rf ${GEOSERVER_HOME}/data_dir/workspaces/* && \
    rm -rf ${GEOSERVER_HOME}/data_dir/layergroups/* && \
    rm -rf ${GEOSERVER_HOME}/data_dir/data/* && \
    rm -rf ${GEOSERVER_HOME}/data_dir/coverages/* && \
    rm -rf ${GEOSERVER_HOME}/data_dir/demo && \
    rm -rf ${GEOSERVER_HOME}/data_dir/logs

# Install Marlin
ARG MARLIN_VERSION=0.9.1
RUN FILENAME=$(echo "marlin-${MARLIN_VERSION}-Unsafe.jar") && \
    if [ ! -f ${TEMP_PATH}/${FILENAME} ]; then \
        URL="https://github.com/bourgesl/marlin-renderer/releases/download/v0_9_1//${FILENAME}" && \
        curl -L $URL --output ${TEMP_PATH}/${FILENAME} ; \
    fi; \
    cp ${TEMP_PATH}/$FILENAME ${GEOSERVER_HOME}/lib

ENV MARLIN_JAR="${GEOSERVER_HOME}/lib/marlin-${MARLIN_VERSION}-Unsafe.jar"

# Install Turbo JPEG
ARG TURBO_JPEG_VERSION=1.5.3
RUN TURBO_JPEG_FILENAME=$(echo "libjpeg-turbo-official_${TURBO_JPEG_VERSION}_amd64.deb") && \
    if [ ! -f ${TEMP_PATH}/${TURBO_JPEG_FILENAME} ]; then \
        URL="https://sourceforge.net/projects/libjpeg-turbo/files/${TURBO_JPEG_VERSION}/${TURBO_JPEG_FILENAME}" && \
        curl -L $URL --output ${TEMP_PATH}/${TURBO_JPEG_FILENAME} ; \
    fi; \
    dpkg -i ${TEMP_PATH}/$TURBO_JPEG_FILENAME

# Install JAI & Image IO
ARG JAI_VERSION=1_1_3
ARG IMAGE_IO_VERSION=1_1

RUN rm ${GEOSERVER_HOME}/webapps/geoserver/WEB-INF/lib/jai_*jar && \
    cd $JAVA_HOME && \
    echo $JAVA_HOME && \
    JAI_FILENAME=$(echo "jai-${JAI_VERSION}-lib-linux-amd64-jdk.bin") && \
    if [ ! -f ${TEMP_PATH}/${JAI_FILENAME} ]; then \
        URL="http://data.boundlessgeo.com/suite/jai/${JAI_FILENAME}" && \
        curl -L $URL --output $TEMP_PATH/$JAI_FILENAME ; \
    fi; \
    mv $TEMP_PATH/$JAI_FILENAME $JAVA_HOME && \
    echo "yes" | sh $JAI_FILENAME && \
    rm $JAI_FILENAME && \
    export _POSIX2_VERSION=199209 && \
    IMAGE_IO_FILENAME="jai_imageio-${IMAGE_IO_VERSION}-lib-linux-amd64-jdk.bin" && \
    if [ ! -f ${TEMP_PATH}/${IMAGE_IO_FILENAME} ]; then \
        URL="http://data.opengeo.org/suite/jai/${IMAGE_IO_FILENAME}" && \
        curl -L $URL --output $TEMP_PATH/$IMAGE_IO_FILENAME ; \
    fi; \
    mv $TEMP_PATH/$IMAGE_IO_FILENAME $JAVA_HOME && \
    echo "yes" | sh $IMAGE_IO_FILENAME && \
    rm $IMAGE_IO_FILENAME

# Install GeoServer Plugins
RUN URL="https://sourceforge.net/projects/geoserver/files/GeoServer/${GEOSERVER_VERSION}/extensions" && \
    for PLUGIN in ${GEOSERVER_PLUGINS}; \
    do \
        FILENAME="geoserver-${GEOSERVER_VERSION}-${PLUGIN}-plugin.zip" && \
        if [ ! -f ${TEMP_PATH}/${FILENAME} ]; then \
            curl -L "$URL/$FILENAME" -o "${TEMP_PATH}/${FILENAME}" ; \
        fi; \
        unzip -o "${TEMP_PATH}/${FILENAME}" -d "${GEOSERVER_HOME}/webapps/geoserver/WEB-INF/lib/" ; \
    done

# Install GeoServer Community Plugins
RUN URL="http://ares.boundlessgeo.com/geoserver/${GEOSERVER_MAJOR_VERSION}.x/community-latest" && \
    for PLUGIN in ${GEOSERVER_COMMUNITY_PLUGINS}; \
    do \
        FILENAME="geoserver-${GEOSERVER_MAJOR_VERSION}-SNAPSHOT-${PLUGIN}-plugin.zip" && \
        if [ ! -f ${TEMP_PATH}/${FILENAME} ]; then \
            curl -L $URL/$FILENAME -o ${TEMP_PATH}/${FILENAME} ; \
        fi; \
        unzip -o ${TEMP_PATH}/${FILENAME} -d ${GEOSERVER_HOME}/webapps/geoserver/WEB-INF/lib/ ; \
    done

ARG GDAL_VERSION="2.1.2"
RUN rm ${GEOSERVER_HOME}/webapps/geoserver/WEB-INF/lib/imageio-ext-gdal-bindings-*.jar && \
    ln -s /usr/share/java/gdal.jar \
        "${GEOSERVER_HOME}/webapps/geoserver/WEB-INF/lib/imageio-ext-gdal-bindings-${GDAL_VERSION}.jar"

# Clean
RUN rm -fr ${TEMP_PATH} && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean

COPY ./scripts /

EXPOSE 8080

ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["/opt/geoserver/bin/startup.sh"]
