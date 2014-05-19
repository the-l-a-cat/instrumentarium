#!/bin/sh

# kin @ agava Tue 06 May 2014

# Purpose: Install the latest possible version of a specified
# package available for the current system.


if test -z "$1"
then
    echo "Usage: get_me_a_pkg.sh PACKAGE
    e.g. get_me_a_pkg.sh smartmontools"
    exit 1
fi

my_version=`uname -r | cut -d- -f 1-2`
my_architecture=`uname -m` 
package=$1

cd /tmp 

if false
then :

elif fetch "http://ftp-archive.freebsd.org\
/mirror/FreeBSD-Archive/old-releases\
/$my_architecture/$my_version/packages/Latest/$package.tgz" ||
	fetch "http://ftp-archive.freebsd.org\
/mirror/FreeBSD/ports/packages/Latest/$package.tbz" 

then
    echo "Fetched $package from the official old-releases archive."

elif fetch "http://ftp-archive.freebsd.org\
/mirror/FreeBSD/ports/packages/Latest/$package.tgz" ||
	fetch "http://ftp-archive.freebsd.org\
/mirror/FreeBSD/ports/packages/Latest/$package.tbz"

then
    echo "Fetched $package from the official archive."

else 
    echo "An error occured while trying to fetch the package specified."
    exit 1
fi

if
    test -f "$package.tbz"
then
    pkg_add "$package.tbz"
elif
    test -f "$package.tgz"
then
    pkg_add "$package.tgz" 
else
    echo "An error occured while trying to install the package specified."
    exit 1
fi
