#!/bin/sh

# Environment variables (all optional)
# CFLAGS - flags for gcc
# NOSTRIP - don't strip output
# INSTALL_DIR - vbox install directory

if [ $# -ne 2 ]; then
	echo "Usage: $0 include-dir vdfuse.c"
	exit 255
fi

if [ -z "${CFLAGS}" ]; then
	CFLAGS="-pipe"
fi

incdir="$1"
infile="$2"
outfile="${infile%.c}"

if ! [ -e "${infile}" ]; then
	echo "${infile} not found."
	exit 1
fi

if [ -z "${INSTALL_DIR}" ]; then
	if [ -e "/etc/vbox/vbox.cfg" ]; then
		. /etc/vbox/vbox.cfg
	elif [ -d "/usr/lib/virtualbox" ]; then
		INSTALL_DIR="/usr/lib/virtualbox"
	elif [ -z "${INSTALL_DIR}" ]; then
		echo "INSTALL_DIR not defined"
		exit 1
	fi
fi

pkg-config --exists fuse
if [ $? -ne 0 ]; then
	echo "FUSE headers not found. Are they installed?"
	echo "(Run 'apt-get install libfuse-dev' on Ubuntu / Debian)"
	exit 1
fi

oldvboxhdd=""
if [ -e "${incdir}/VBox/VBoxHDD-new.h" ]; then
	oldvboxhdd="-DOLDVBOXHDD"
elif ! [ -e "${incdir}/VBox/VBoxHDD.h" ]; then
	echo "Invalid include directory. Make sure that it has the VBox directory inside."
	exit 1
fi

gcc "${infile}" -o "${outfile}" \
	`pkg-config --cflags --libs fuse` \
	-I"${incdir}" \
	-Wl,-rpath,"${INSTALL_DIR}" \
	-l:"${INSTALL_DIR}"/VBoxDD.so \
	-Wall ${oldvboxhdd} ${CFLAGS}

if [ -z "${NOSTRIP}" ]; then
	strip -sx "${outfile}"
fi

if [ $? -eq 0 ]; then
	echo "Success!"
else
	echo "Compile Failed!"
fi
