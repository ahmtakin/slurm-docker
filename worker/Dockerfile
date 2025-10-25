FROM slurm-base:latest
COPY start.sh /start.sh
COPY build_sandbox.sh /usr/local/bin/build-apptainer-sandbox
RUN chmod +x /start.sh /usr/local/bin/build-apptainer-sandbox
ENTRYPOINT ["/usr/bin/tini","--"]
CMD ["/start.sh"]
