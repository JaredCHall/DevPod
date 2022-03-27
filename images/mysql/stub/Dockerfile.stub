
# Install somewhere easy to clean up
RUN mkdir /tmp/build-image/
WORKDIR /tmp/build-image/

# Install MariaDB
ARG MYSQL_VERSION=8.0
COPY mysql-apt-config.deb ./
COPY mysql-install.sh ./
RUN ./mysql-install.sh "${MYSQL_VERSION}"

# Configure MariaDB
COPY etc/my.cnf ./
COPY mysql-configure.sh ./
ARG MYSQL_USER
ARG MYSQL_PASS
RUN ./mysql-configure.sh "$MYSQL_USER" "$MYSQL_PASS"

# Clean up
WORKDIR /root/
RUN rm -r /tmp/build-image;

# Set entrypoint, the script executed when container is run
COPY start.sh ./
ENTRYPOINT [ "/root/start.sh" ]