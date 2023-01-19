
# Install somewhere easy to clean up
RUN cd /var/www
WORKDIR /var/www


# Install MariaDB
COPY nodejs-install.sh ./
ARG PODMAN_NODE_VERSION
RUN ./nodejs-install.sh "${PODMAN_NODE_VERSION}"

# Clean up
WORKDIR /root/
#RUN rm -r /tmp/build-image;

# Set entrypoint, the script executed when container is run
COPY start.sh ./
ENTRYPOINT [ "/root/start.sh" ]