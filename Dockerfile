from alpine

run  apk add --update curl bash tar \
 &&  rm -rf /var/cache/apk/*

run  curl -sL https://github.com/mholt/caddy/releases/download/v0.9.0/caddy_linux_amd64.tar.gz \
     | tar -v -z -x -C /bin caddy_linux_amd64 \
 &&  mv /bin/caddy_linux_amd64 /bin/caddy \
 &&  chmod a+x /bin/caddy

expose 80

add  docker-entrypoint.sh /bin/coreos-local-mirror
entrypoint ["coreos-local-mirror"]
cmd ["--platforms=amd64-usr","--channels=alpha","current:pxe,iso"]