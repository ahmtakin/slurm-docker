FROM slurm-base:latest
COPY start.sh /start.sh
RUN chmod +x /start.sh
ENTRYPOINT ["/usr/bin/tini","--"]
CMD ["/start.sh"]
