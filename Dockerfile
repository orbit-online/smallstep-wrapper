FROM smallstep/step-kms-plugin:0.8.2
ARG BUILT_BY=<unknown> BUILD_TOOL=cli
LABEL cr.orbit.dev/build-src="https://github.com/orbit-online/smallstep-wrapper" cr.orbit.dev/built-by=$BUILT_BY cr.orbit.dev/build-tool=$BUILD_TOOL
USER root
WORKDIR /
RUN deluser step
ENV STEPPATH=
RUN rm -rf /home/step
RUN apk --no-cache add su-exec bash jq p11-kit-server gnutls-utils openssl

COPY --chmod=755 step-wrapper.sh /usr/local/bin/step-wrapper
COPY --chmod=755 entrypoint.sh /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
