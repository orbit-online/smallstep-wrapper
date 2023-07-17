FROM smallstep/step-kms-plugin:0.8.2
USER root
WORKDIR /
RUN deluser step
ENV STEPPATH=
RUN rm -rf /home/step
RUN apk --no-cache add su-exec bash jq p11-kit-server gnutls-utils openssl

COPY --chmod=755 step-wrapper.sh /usr/local/bin/step-wrapper
COPY --chmod=755 entrypoint.sh /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
