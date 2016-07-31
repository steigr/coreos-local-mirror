#!/usr/bin/env bash

MIRROR_DIR=${MIRROR_DIR:-/mirror}

set -eo pipefail
[[ -z "$TRACE" ]] || set -x

# run command if it exists
command -v -- "$1" >/dev/null && exec "$@"

while true; do
	[[ $# -gt 0 ]] || break
	arg="$1"
	[[ $# -le 0 ]] || shift
	case "$arg" in
		--platforms=*)
			export PLATFORMS="${arg#*=}"
		;;
		--channels=*)
			export CHANNELS="${arg#*=}"
		;;
		--*)
			echo "Unkown Option '$arg'"
		;;
		*)
			set -- "$arg" "$@"
			break
		;;
	esac
done

export PLATFORMS="${PLATFORMS:-amd64-usr}"
export CHANNELS="${CHANNELS:-alpha}"
export FORMATS="pxe"
export VERSION="current"

[[ -d $MIRROR_DIR ]] || mkdir -p $MIRROR_DIR

log() {
	echo "$@"
}

download_pxe() {
	local channel=$1
	local platform=$2
	local release=$3
	[[ -d $MIRROR_DIR/$channel/$platform/$release ]] || mkdir -p $MIRROR_DIR/$channel/$platform/$release
	for file in coreos_production_pxe.vmlinuz coreos_production_pxe.vmlinuz.sig coreos_production_pxe.vmlinuz coreos_production_pxe_image.cpio.gz coreos_production_pxe_image.cpio.gz.sig; do
		local url=https://$channel.release.core-os.net/$platform/$release/$file
		local file=$MIRROR_DIR/$channel/$platform/$release/$file
		[[ ! -f $file ]] || continue
		log "Downloading $url -> $file"
		curl -s -L -o "$file" "$url"
	done
}

download_iso() {
	local channel=$1
	local platform=$2
	local release=$3
	[[ -d $MIRROR_DIR/$channel/$platform/$release ]] || mkdir -p $MIRROR_DIR/$channel/$platform/$release
	for file in coreos_production_iso_image.iso; do
		local url=https://$channel.release.core-os.net/$platform/$release/$file
		local file=$MIRROR_DIR/$channel/$platform/$release/$file
		[[ ! -f $file ]] || continue
		log "Downloading $url -> $file"
		curl -s -L -o "$file" "$url"
	done
}

for release in $*; do

	version=${release%:*}
	version=${version:-$VERSION}
	formats=${release#*:}
	formats=${formats:-$FORMATS}

	echo -e ${formats//,/\\n} | while read -r format; do
		handler=download_$format
		echo -e ${PLATFORMS//,/\\n} | while read -r platform; do
			echo -e ${CHANNELS//,/\\n} | while read -r channel; do
				$handler $channel $platform $version
			done
		done
	done
done

cat<<Caddyfile > /Caddyfile
*:80
root $MIRROR_DIR
Caddyfile

cd /
exec caddy