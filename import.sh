#!/bin/bash

set -e

if [ ! "$DISTRO" ]; then
	echo "No DISTRO env var, run 'make shell' to use this tool manually"
	exit 1
fi

repo=/debian
archive=/archive-$DISTRO
pdistro=quadpbx-$DISTRO

reprepro -v -b $repo checkpool
STATUS=$?
if [ "$STATUS" -ne 0 ]; then
	echo "Problems with the pool. You probably want to run something like:"
	echo "  reprepro -v -b $repo remove $pdistro main __pakagename__"
	echo "List of all packages, so you know which one to remove are:"
	reprepro -v -b $repo list $pdistro
	exit 1
fi

reprepro -v -b $repo clearvanished
reprepro -v -b $repo createsymlinks

get_filehash() {
	sha256sum $1 | cut -d\  -f1
}

for dpkg in /incoming/*deb; do
	# Make sure there's file to import
	[ ! -e "$dpkg" ] && continue

	aopt=""
	arch=$(dpkg-deb -f ${dpkg} Architecture)
	pkg=$(dpkg-deb -f ${dpkg} Package)
	src=$(dpkg-deb -f ${dpkg} Source)

	[ "$arch" != 'all' ] && aopt="-A $arch"
	base=$(basename $dpkg)

	if [ "$src" ]; then
		destfile=$repo/pool/main/${src:0:1}/$src/$base
	else
		destfile=$repo/pool/main/${base:0:1}/$pkg/$base
	fi

	thishash=$(get_filehash $dpkg)
	archivedest=$archive/$base.$thishash

	# Copy it to the archive if it doesn't exist
	if [ ! -e "$archivedest" ]; then
		/bin/cp -f $dpkg $archivedest
		/bin/cp -f $dpkg $archive/$base
	fi
	# Is this package already in our repo?
	if [ -e $destfile ]; then
		# It exists. Is it the same?
		if [ "$thishash" == "$(get_filehash $destfile)" ]; then
			# It is, delete and continue
			rm -f $dpkg
			continue
		fi
		# It's different. Remove it from the repo
		reprepro -v -b $repo ${aopt} remove $pdistro $pkg
		reprepro -v -b $repo deleteunreferenced
	fi
	#echo reprepro -v -b $repo ${aopt} -C main includedeb $pdistro $dpkg
	reprepro -v -b $repo ${aopt} -C main includedeb $pdistro $dpkg && rm -f $dpkg
done
