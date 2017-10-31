#!/bin/bash -e

GITVERSION=`git describe --always`
SOURCEDIR=$1
BUILDDIR=$SOURCEDIR/build
PKGDIR=$SOURCEDIR/pkg
PLUGIN=`echo $SOURCEDIR | grep -oh "snap-.*"`
ROOTFS=$BUILDDIR/rootfs
BUILDCMD='go build -a -ldflags "-w"'

build_type="code"
if [ $# -gt 1 ]; then
  build_type="$2"
fi

if [ "$build_type" = "code" ]; then
  echo
  echo "****  Snap Plugin Build  ****"
  echo

  # Disable CGO for builds
  export CGO_ENABLED=0

  # Clean build bin dir
  rm -rf $ROOTFS/*

  # Make dir
  mkdir -p $ROOTFS

  # Build plugin
  echo "Source Dir = $SOURCEDIR"
  echo "Building Snap Plugin: $PLUGIN"
  $BUILDCMD -o $ROOTFS/$PLUGIN
elif [ "$build_type" = "pkg" ]; then
  # builds a standalone package
  gem list | grep fpm >/dev/null 2>&1 || { \
	  echo "\033[1;33mfpm is not installed. See https://github.com/jordansissel/fpm\033[m"; \
	  echo "$$ gem install fpm"; \
	  exit 1; \
	}

  type rpmbuild >/dev/null 2>&1 || { \
	  echo "\033[1;33mrpmbuild is not installed. See the package for your distribution\033[m"; \
	  exit 1; \
	}

  echo "removing: ${PKGDIR:?}/*"
  rm -rf "${PKGDIR:?}/"*

  VERNUM=$(tr -s [" "\\t] [" "" "]  < "${SOURCEDIR}/ping/ping.go" | grep "Version = " | cut -d" " -f4)
  mkdir -p pkg/tmp/opt/snap_plugins/bin
  cp -f "${ROOTFS}/${PLUGIN}" pkg/tmp/opt/snap_plugins/bin
  (cd ${PKGDIR} && \
  fpm -s dir -C tmp -t deb \
    -n ${PLUGIN} \
    -m "Papertrail <support@papertrailapp.com>" \
    -v ${VERNUM} \
    -d "snap-telemetry|appoptics-snaptel" \
    --license "Apache" \
    --url "https://www.papertrail.com" \
    --description "Ping plugin for the Intel snap agent" \
    --vendor "Papertrail" \
    opt/snap_plugins/bin/${PLUGIN} && \
  fpm -s dir -C tmp -t rpm \
    -n ${PLUGIN} \
    -m "Papertrail <support@papertrailapp.com>" \
    -v ${VERNUM} \
    -d "snap-telemetry|appoptics-snaptel" \
    --license "Apache" \
    --url "https://www.papertrail.com" \
    --description "Ping plugin for the Intel snap agent" \
    --vendor "Papertrail" \
    opt/snap_plugins/bin/${PLUGIN})
  rm -R -f pkg/tmp
else
  echo "Must pass in a build type of either code or pkg"
  exit 1
fi
