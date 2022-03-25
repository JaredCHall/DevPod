
# Install somewhere easy to clean up
RUN mkdir /tmp/build-image/
WORKDIR /tmp/build-image/

# Install MariaDB
COPY mariadb-install.sh ./
RUN ./mariadb-install.sh "${MARIADB_VERSION}"

# Configure MariaDB
COPY etc/my.cnf ./
COPY mariadb-configure.sh ./
ARG MARIADB_USER
ARG MARIADB_PASS
RUN ./mariadb-configure.sh "$MARIADB_USER" "$MARIADB_PASS"

# Clean up
WORKDIR /root/
RUN rm -r /tmp/build-image;

# Set entrypoint, the script executed when container is run
COPY start.sh ./
ENTRYPOINT [ "/root/start.sh" ]