FROM alpine:3.7 AS build-env

ENV OC_VERSION=0.12.1

## build ocserv and install it to $DESTDIR 
## calculate runtime dependencies and save it to $DESTDIR/runtime.deps
RUN buildDeps=" \
		curl \
		g++ \
		gnutls-dev \
		gpgme \
		libev-dev \
		libnl3-dev \
		libseccomp-dev \
		linux-headers \
		linux-pam-dev \
		lz4-dev \
		make \
		readline-dev \
		tar \
		xz \
	"; \
	set -x \
	&& apk add --update --virtual .build-deps $buildDeps \
	&& curl -SL "ftp://ftp.infradead.org/pub/ocserv/ocserv-$OC_VERSION.tar.xz" -o ocserv.tar.xz \
	&& curl -SL "ftp://ftp.infradead.org/pub/ocserv/ocserv-$OC_VERSION.tar.xz.sig" -o ocserv.tar.xz.sig \
	&& mkdir -p /usr/src/ocserv \
	&& tar -xf ocserv.tar.xz -C /usr/src/ocserv --strip-components=1 \
	&& cd /usr/src/ocserv \
	&& ./configure \
	&& make \
	&& export DESTDIR=/app/build/ \
	&& make install \
	&& runDeps="$( \
		scanelf --needed --nobanner $DESTDIR/usr/local/sbin/ocserv \
			| awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
			| xargs -r apk info --installed \
			| sort -u \
		)" \ 
	&& echo $runDeps > $DESTDIR/runtime.deps



FROM alpine:3.7
COPY --from=build-env /app/build/  /
COPY --from=build-env /usr/src/ocserv/doc/sample.config  /app/ocserv/ocserv.conf
# Setup some config
COPY ocserv/  /app/ocserv/	
COPY cn-no-route.txt /app/

RUN apk add --no-cache --virtual .run-deps `cat /runtime.deps` gnutls-utils iptables libnl3 readline

EXPOSE 443
COPY init.sh /app/init.sh
COPY start.sh /app/start.sh
RUN chmod 755 /app/start.sh
CMD ["/app/start.sh"]


