#!/bin/sh

set -e

AUTOMAKE="yes"
LIGHTNING=1
SUPPORTDIR="$(pwd)"
: ${prefix="$SUPPORTDIR/install"}

case `uname -s` in
    CYGWIN*)
	CC="gcc -mno-cygwin"
	;;
    *)
	CC=gcc
	;;
esac

##
## Build Support Libraries: Automake/SEAM
##

## Automake version to use
amversion="1.7.6"

if [ "x${AUTOMAKE}" != "x" ]; then
    if test -d "${SUPPORTDIR}/automake-seam/automake-${amversion}"; then
	echo "### Automake/SEAM has been configured already." >&2
	echo "### Please delete the following directory to re-configure it:" >&2
	echo "### ${SUPPORTDIR}/automake-seam/automake-${amversion}" >&2
    else
	echo "### Building Automake/SEAM" >&2
	cd "${SUPPORTDIR}/automake-seam" && (
	    echo "### - extracting the source" >&2
	    tar xzf automake-${amversion}.tar.gz
	    cd automake-${amversion} && (
		echo "### - applying SEAM-specific patches" >&2
		patch -p1 < ../automake-${amversion}.seam.patch
		patch -p1 < ../automake2automake-seam.patch
		echo "### - reconfiguring the source" >&2
		libtoolize --automake && aclocal && automake && autoconf &&
		./configure --prefix="${prefix}" &&
		echo "### - building and installing" >&2
		make all install
		echo "### - linking local and global ac dir" >&2
		if which aclocal; then
		    aclocal --print-ac-dir > "${prefix}/share/aclocal-1.7/dirlist"
		fi
	    )
	)
    fi
fi

##
## Build Support Libraries: Lightning
##

# lightning version to use
lightningversion=1.1.3pre

if [ "$LIGHTNING" -ne 0 ]
then
    if test -d "${SUPPORTDIR}/lightning/lightning-${lightningversion}"; then
	echo "### Lightning/SEAM has been configured already." >&2
	echo "### Please delete the following directory to re-configure it:" >&2
	echo "### ${SUPPORTDIR}/lightning/lightning-${lightningversion}" >&2
    else
	echo "### Building lightning/SEAM" >&2
	cd "${SUPPORTDIR}/lightning" && (
	    echo "### - extracting the source" >&2
	    tar xzf lightning-${lightningversion}.tar.gz
	    cd lightning-${lightningversion} && (
		echo "### - applying SEAM-specific patches" >&2
		patch -p1 < ../lightning-${lightningversion}.seam.patch
		echo "### - reconfiguring the source" >&2
		mkdir -p "${SUPPORTDIR}/build/lightning" 2>/dev/null
		cd "${SUPPORTDIR}/build/lightning" &&
		"${SUPPORTDIR}/lightning/lightning-${lightningversion}/configure" CC="$CC" --prefix="$prefix" &&
		echo "### - building and installing" >&2 &&
		make all install
	    )
	)
    fi
fi

##
## Build Support Libraries: zlib
##
if [ ! -f "$prefix/include/zlib.h" ]
then
    (
	cd "$SUPPORTDIR/zlib" &&
	CC="$CC" ./configure --prefix="$prefix" &&
	make all install distclean
    ) || exit 1
fi

##
## Clean up aclocal path mess
##

echo "### Clean up aclocal path mess" >&2
cp "$prefix"/share/aclocal-1.7/* "$prefix"/share/aclocal/
