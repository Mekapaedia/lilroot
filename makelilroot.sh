#!/bin/sh

REPOS_DIR="${HOME}/code"
LILROOT_DIR="lilroot"
TARGET="x86_64-linux-musl"
INSTALL_PREFIX="${REPOS_DIR}/${LILROOT_DIR}"
LIB_DIR="${INSTALL_PREFIX}/lib"
BIN_DIR="${INSTALL_PREFIX}/bin"

MUSL_URL="git://git.musl-libc.org/musl"
MUSL_DIR="musl"
MUSL_SRC_DIR="${REPOS_DIR}/${MUSL_DIR}"
MUSL_CC="musl-gcc"
MUSL_CC_PATH="${BIN_DIR}/${MUSL_CC}"

BASE_URL="git://git.suckless.org/sbase"
BASE_DIR="sbase"
BASE_SRC_DIR="${REPOS_DIR}/${BASE_DIR}"

ZLIB_URL="https://github.com/madler/zlib.git"
ZLIB_DIR="zlib"
ZLIB_SRC_DIR="${REPOS_DIR}/${ZLIB_DIR}"

BINUTILS_VER="2.33.1"
BINUTILS_URL="https://ftp.gnu.org/gnu/binutils/binutils-${BINUTILS_VER}.tar.gz"
BINUTILS_DIR="binutils-${BINUTILS_VER}"
BINUTILS_SRC_DIR="${REPOS_DIR}/${BINUTILS_DIR}"

MAKE_VER="4.2.1"
MAKE_URL="https://ftp.gnu.org/gnu/make/make-${MAKE_VER}.tar.gz"
MAKE_DIR="make-${MAKE_VER}"
MAKE_SRC_DIR="${REPOS_DIR}/${MAKE_DIR}"

NETBSD_CURSES_URL="https://github.com/sabotage-linux/netbsd-curses.git"
NETBSD_CURSES_DIR="netbsd-curses"
NETBSD_CURSES_SRC_DIR="${REPOS_DIR}/${NETBSD_CURSES_DIR}"

OKSH_URL="https://github.com/Mekapaedia/oksh"
OKSH_DIR="oksh"
OKSH_SRC_DIR="${REPOS_DIR}/${OKSH_DIR}"

clone_cd_rebase()
{
    if [ ! -d  "$2" ]
    then
        git clone "$1" "$2" || return 1
    fi
    cd "$2" || return 1
    git pull --rebase --autostash || return 1
}

build_musl()
{
    clone_cd_rebase "${MUSL_URL}" "${MUSL_SRC_DIR}" || return 1
    make distclean
    ./configure \
        --prefix="${INSTALL_PREFIX}" \
        --syslibdir="${LIB_DIR}" \
        || return 1
    make || return 1
    make install || return 1
}

build_base()
{
    PATH="${BIN_DIR}:${PATH}"
    clone_cd_rebase "${BASE_URL}" "${BASE_SRC_DIR}" || return 1
    make clean
    git restore config.mk || return 1
    mv config.mk config.mk.orig
    sed "s|/usr/local|${INSTALL_PREFIX}|" <config.mk.orig >config.mk || return 1
    echo "CC = ${MUSL_CC}" >> config.mk
    echo "LDFLAGS = -static" >> config.mk
    echo "CFLAGS = -Os -fPIC -static" >> config.mk
    make all install || return 1
    ln -sf "${BIN_DIR}/xinstall" "${BIN_DIR}/install"
}

build_zlib()
{
    PATH="${BIN_DIR}:${PATH}"
    clone_cd_rebase "${ZLIB_URL}" "${ZLIB_SRC_DIR}" || return 1
    make distclean
    CC="${MUSL_CC}" ./configure \
        --prefix="${INSTALL_PREFIX}" \
        --64 \
        || return 1
    make static LDFLAGS="-static" || return 1
    make shared || return 1
    make install || return 1
    cp minigzip "${BIN_DIR}"
    ln -sf "${BIN_DIR}/minigzip" "${BIN_DIR}/gzip"
}

build_binutils()
{
    PATH="${BIN_DIR}:${PATH}"
    if [ ! -d "${BINUTILS_DIR}" ]
    then
        rm -f "${BINUTILS_DIR}.tar.gz"
        cd "${REPOS_DIR}" || return 1
        wget "${BINUTILS_URL}" || return 1
        gzip -d "${BINUTILS_DIR}.tar.gz" || return 1
        tar -x -f "${BINUTILS_DIR}.tar" || return 1
    fi
    cd "${BINUTILS_SRC_DIR}" || return 1
    if [ -f "Makefile" ]
    then
        make distclean
    fi
    ./configure \
        --prefix="${INSTALL_PREFIX}" \
        CC="${MUSL_CC}" \
        CFLAGS="-Os -fPIC" \
        LDFLAGS="-static --static" \
        --with-build-libsubdir="${LIB_DIR}" \
        --build="${TARGET}" \
        --disable-nls \
        --disable-gdb \
        --disable-gold \
        --disable-libquadmath \
        --with-system-libz \
        --with-target-system-zlib=true \
        --enable-objc-gc=false \
        --with-pic \
        --disable-libada \
        --disable-libssp \
        --disable-gcov \
        --enable-plugins \
        --disable-multilib \
        --without-libiconv-prefix \
        --disable-libstdcxx \
        || return 1
    make MAKEINFO=true || return 1
    make install-strip || return 1
    rm -rf "${INSTALL_PREFIX}/share/info"
}

build_make()
{
    PATH="${BIN_DIR}:${PATH}"
    if [ ! -d "${MAKE_DIR}" ]
    then
        rm -f "${MAKE_DIR}.tar.gz"
        cd "${REPOS_DIR}" || return 1
        wget "${MAKE_URL}" || return 1
        gzip -d "${MAKE_DIR}.tar.gz" || return 1
        tar -x -f "${MAKE_DIR}.tar" || return 1
    fi
    cd "${MAKE_SRC_DIR}" || return 1
    if [ -f "Makefile" ]
    then
        make distclean
    fi
    ./configure \
        --prefix="${INSTALL_PREFIX}" \
        CC="${MUSL_CC}" \
        CFLAGS="-Os -fPIC" \
        LDFLAGS="-static --static" \
        MAKEINFO=true \
        --disable-nls \
        || return 1
    make || return 1
    make install || return 1
    rm -rf "${INSTALL_PREFIX}/share/info"
}

build_netbsd_curses()
{
    PATH="${BIN_DIR}:${PATH}"
    clone_cd_rebase "${NETBSD_CURSES_URL}" "${NETBSD_CURSES_SRC_DIR}" || return 1
    make clean
    make -f GNUmakefile \
        PREFIX="${INSTALL_PREFIX}" \
        CC="${MUSL_CC}" \
        CFLAGS="-Os -Wall -fPIC" \
        LDFLAGS="-static" \
        all-static \
        install-static \
        || return 1
}

build_oksh()
{
    PATH="${BIN_DIR}:${PATH}"
    clone_cd_rebase "${OKSH_URL}" "${OKSH_SRC_DIR}" || return 1
    if [ -f "Makefile" ]
    then
        make distclean
    fi
    LDFLAGS="-L${LIB_DIR}" \`
    ./configure \
        --prefix="${INSTALL_PREFIX}" \
        --cc="${MUSL_CC}" \
        --cflags="-Os -fPIC" \
        --enable-static \
        || return 1
    make || return 1
    make install || return 1
}

BUILD_MUSL=0
BUILD_BASE=0
BUILD_ZLIB=0
BUILD_BINUTILS=0
BUILD_MAKE=0
BUILD_NETBSD_CURSES=0
BUILD_OKSH=0

while [ "$#" -gt 0 ]
do
    case $1 in
        musl)
            BUILD_MUSL=1
            shift
            ;;
        base)
            BUILD_BASE=1
            shift
            ;;
        zlib)
            BUILD_ZLIB=1
            shift
            ;;
        binutils)
            BUILD_BINUTILS=1
            shift
            ;;
        make)
            BUILD_MAKE=1
            shift
            ;;
        netbsd-curses)
            BUILD_NETBSD_CURSES=1
            shift
            ;;
        oksh)
            BUILD_OKSH=1
            shift
            ;;
        all)
            BUILD_MUSL=1
            BUILD_BASE=1
            BUILD_ZLIB=1
            BUILD_BINUTILS=1
            BUILD_MAKE=1
            BUILD_NETBSD_CURSES=1
            BUILD_OKSH=1
            shift
            ;;
        *)
            echo "Unknown arg $1"
            exit 1
            ;;
    esac
done

mkdir -p "${INSTALL_PREFIX}"

if [ "${BUILD_MUSL}" -eq 1 ]
then
    build_musl || exit 1
fi

if [ "${BUILD_BASE}" -eq 1 ]
then
    build_base || exit 1
fi

if [ "${BUILD_ZLIB}" -eq 1 ]
then
    build_zlib || exit 1
fi

if [ "${BUILD_BINUTILS}" -eq 1 ]
then
    build_binutils || exit 1
fi

if [ "${BUILD_MAKE}" -eq 1 ]
then
    build_make || exit 1
fi

if [ "${BUILD_NETBSD_CURSES}" -eq 1 ]
then
    build_netbsd_curses || exit 1
fi

if [ "${BUILD_OKSH}" -eq 1 ]
then
    build_oksh || exit 1
fi
