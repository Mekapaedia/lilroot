#!/bin/sh

REPOS_DIR="${PWD}"
LILROOT_DIR="lilroot"
TARGET="x86_64-linux-musl"
INSTALL_PREFIX="${REPOS_DIR}/${LILROOT_DIR}"
LIB_DIR="${INSTALL_PREFIX}/lib"
BIN_DIR="${INSTALL_PREFIX}/bin"
INCLUDE_DIR="${INSTALL_PREFIX}/include"

MUSL_URL="git://git.musl-libc.org/musl"
MUSL_DIR="musl"
MUSL_SRC_DIR="${REPOS_DIR}/${MUSL_DIR}"
MUSL_BASE_CC="gcc"
MUSL_CC="musl-${MUSL_BASE_CC}"
MUSL_CC_PATH="${BIN_DIR}/${MUSL_CC}"
MUSL_CFLAGS="-Os -fPIC -fno-use-linker-plugin"
MUSL_LIBS="-L${LIB_DIR}"
MUSL_LDFLAGS="-fno-use-linker-plugin ${MUSL_LIBS}"

BYACC_VER="20240109"
BYACC_DIR="byacc-${BYACC_VER}"
BYACC_URL="https://invisible-island.net/datafiles/release/byacc.tar.gz"
BYACC_SRC_DIR="${REPOS_DIR}/${BYACC_DIR}"

LEX_URL="https://github.com/sabotage-linux/lex.git"
LEX_DIR="lex"
LEX_SRC_DIR="${REPOS_DIR}/${LEX_DIR}"

ZLIB_URL="https://github.com/madler/zlib.git"
ZLIB_DIR="zlib"
ZLIB_SRC_DIR="${REPOS_DIR}/${ZLIB_DIR}"

BUSYBOX_VER="1.36.1"
BUSYBOX_DIR="busybox-${BUSYBOX_VER}"
BUSYBOX_URL="https://www.busybox.net/downloads/busybox-${BUSYBOX_VER}.tar.bz2"
BUSYBOX_SRC_DIR="${REPOS_DIR}/${BUSYBOX_DIR}"
BUSYBOX_CONFIG="${REPOS_DIR}/busybox_config"

DROPBEAR_URL="https://github.com/mkj/dropbear.git"
DROPBEAR_DIR="dropbear"
DROPBEAR_SRC_DIR="${REPOS_DIR}/${DROPBEAR_DIR}"

BEARSSL_URL="https://www.bearssl.org/git/BearSSL"
BEARSSL_DIR="BearSSL"
BEARSSL_SRC_DIR="${REPOS_DIR}/${BEARSSL_DIR}"

CURL_VER="8.4.0"
CURL_URL="https://curl.se/tiny/tiny-curl-${CURL_VER}.tar.gz"
CURL_DIR="tiny-curl-${CURL_VER}"
CURL_SRC_DIR="${REPOS_DIR}/${CURL_DIR}"

GIT_URL="git://git.kernel.org/pub/scm/git/git.git"
GIT_VER="v2.20.5"
GIT_DIR="git"
GIT_SRC_DIR="${REPOS_DIR}/${GIT_DIR}"

BINUTILS_VER="2.33.1"
BINUTILS_URL="https://ftp.gnu.org/gnu/binutils/binutils-${BINUTILS_VER}.tar.gz"
BINUTILS_DIR="binutils-${BINUTILS_VER}"
BINUTILS_SRC_DIR="${REPOS_DIR}/${BINUTILS_DIR}"

MAKE_VER="4.2.1"
MAKE_URL="https://ftp.gnu.org/gnu/make/make-${MAKE_VER}.tar.gz"
MAKE_DIR="make-${MAKE_VER}"
MAKE_SRC_DIR="${REPOS_DIR}/${MAKE_DIR}"

ALL_REPOS="${MUSL_SRC_DIR} \
           ${BYACC_SRC_DIR} \
           ${LEX_SRC_DIR} \
           ${ZLIB_SRC_DIR} \
           ${BUSYBOX_SRC_DIR} \
           ${DROPBEAR_SRC_DIR} \
           ${BEARSSL_SRC_DIR} \
           ${CURL_SRC_DIR} \
           ${GIT_SRC_DIR} \
           ${BINUTILS_SRC_DIR} \
           ${MAKE_SRC_DIR} \
           "

ALL_ARCHIVES="${BYACC_DIR}.tar ${BYACC_DIR}.tar.gz \
              ${BUSYBOX_DIR}.tar ${BUSYBOX_DIR}.tar.bz2 \
              ${CURL_DIR}.tar ${CURL_DIR}.tar.gz \
              ${MAKE_DIR}.tar ${MAKE_DIR}.tar.gz \
              ${BINUTILS_DIR}.tar ${BINUTILS_DIR}.tar.gz \
              "

lilroot_help()
{
cat<<EOF
Useage: $0 [clean|distclean] [programs... | all] [post-clean]

Makes a small statically liked root in $INSTALL_PREFIX

clean: clean build directories prior to build
distclean: clean build + root prior to build
programs: list of programs to build. Currently:
    musl, byacc, lex, zlib, busybox, dropbear, bearssl, curl, git, binutils, make
    (built in that order)
all: build all programs specified above
post-clean: clean build after building (saves space)

This updated 2024-06-23
EOF

}

clean_repos()
{
    cd "${REPOS_DIR}"
    rm -rf ${ALL_REPOS}
}

clean_archives()
{
    cd "${REPOS_DIR}"
    rm -rf ${ALL_ARCHIVES}
}

clean_build()
{
    clean_repos
    clean_archives
}

clean_root()
{
    cd "${REPOS_DIR}"
    rm -rf "${INSTALL_PREFIX}"
}

clone_cd_rebase()
{
    cd "${REPOS_DIR}"
    if [ ! -d  "$2" ]
    then
        git clone "$1" "$2" || return 1
    fi
    cd "$2" || return 1
    if [ -n "$3" ]
    then
        git checkout "$3" || return 1
    else
        git pull --rebase --autostash || return 1
    fi
}

setup_root()
{
    cd "${REPOS_DIR}"
    mkdir -p "${INSTALL_PREFIX}"
    mkdir -p "${INSTALL_PREFIX}/usr"
    mkdir -p "${BIN_DIR}"
    mkdir -p "${LIB_DIR}"
    cd "${INSTALL_PREFIX}/usr" && ln -snf "../bin" "bin"
    cd "${INSTALL_PREFIX}/usr" && ln -snf "../lib" "lib"
    cd "${INSTALL_PREFIX}/usr" && ln -snf "bin" "sbin"
    cd "${INSTALL_PREFIX}" && ln -snf "bin" "sbin"
}

get_archive_cd()
{
    cd "${REPOS_DIR}"
    TAR_EX="tar"
    COMP_EX="${3}"
    DECOMPRESS="gzip"
    if [ "${3}" = "bz2" ]
    then
        DECOMPRESS="bzip2"
    fi
    TARGET_DIR="${1}"
    SRC_NAME="$(basename ${TARGET_DIR})"
    TAR_NAME="${SRC_NAME}.tar"
    ARCHIVE_NAME="${TAR_NAME}.${COMP_EX}"

    if [ ! -d "${TARGET_DIR}" ]
    then
        cd "${REPOS_DIR}" || return 1
        if [ ! -f "${TAR_NAME}" ]
        then
            if [ ! -f "${ARCHIVE_NAME}" ]
            then
                curl "${2}" -o "${ARCHIVE_NAME}" || return 1
            fi
            "${DECOMPRESS}" -d "${ARCHIVE_NAME}" || return 1
        fi
        tar -x -f "${TAR_NAME}" || return 1
    fi
    cd "${TARGET_DIR}" || return 1
}

build_musl()
{
    clone_cd_rebase "${MUSL_URL}" "${MUSL_SRC_DIR}" || return 1
    make distclean
    LDFLAGS="${MUSL_LDFLAGS}" CFLAGS="${MUSL_CFLAGS}" ./configure \
        --prefix="${INSTALL_PREFIX}" \
        --syslibdir="${LIB_DIR}" \
        || return 1
    make || return 1
    make install || return 1
}

build_byacc()
{
    get_archive_cd "${BYACC_SRC_DIR}" "${BYACC_URL}" gz
    if [ -f "Makefile" ]
    then
        make distclean
    fi
    ./configure \
        --prefix="${INSTALL_PREFIX}" \
        --build="${TARGET}" \
        --host="${TARGET}" \
        CC="${MUSL_CC}" \
        CFLAGS="${MUSL_CFLAGS}" \
        LDFLAGS="-static --static ${MUSL_LDFLAGS}" \
        || return 1
    make || return 1
    make install || return 1
    cd "${BIN_DIR}" && ln -sf "yacc" "bison"
}

build_lex()
{
    clone_cd_rebase "${LEX_URL}" "${LEX_SRC_DIR}" || return 1
    make clean
    make \
        PREFIX="${INSTALL_PREFIX}" \
        CC="${MUSL_CC}" \
        CFLAGS="${MUSL_CFLAGS}" \
        HOSTCFLAGS="-static ${MUSL_CFLAGS}" \
        LDFLAGS="-static ${MUSL_LDFLAGS}" \
        install \
        || return 1
    cd "${BIN_DIR}" && ln -sf "lex" "flex"
}

build_zlib()
{
    clone_cd_rebase "${ZLIB_URL}" "${ZLIB_SRC_DIR}" || return 1
    make distclean
    ./configure \
        --prefix="${INSTALL_PREFIX}" \
        --64 \
        --static \
        || return 1
    make static || return 1
    make install || return 1
}

build_busybox()
{
    get_archive_cd "${BUSYBOX_SRC_DIR}" "${BUSYBOX_URL}" bz2
    if [ -f "Makefile" ]
    then
        make distclean
    fi
    cp "${BUSYBOX_CONFIG}" .config || return 1
    make oldconfig V=1 HOSTCC="${MUSL_CC} ${MUSL_CFLAGS} -static" CC="${MUSL_CC} ${MUSL_CFLAGS}" || return 1
    make V=1 HOSTCC="${MUSL_CC} ${MUSL_CFLAGS} -static" CC="${MUSL_CC} ${MUSL_CFLAGS}" || return 1
    make install V=1 HOSTCC="${MUSL_CC} ${MUSL_CFLAGS} -static" CC="${MUSL_CC} ${MUSL_CFLAGS}" || return 1
}

build_dropbear()
{
    clone_cd_rebase "${DROPBEAR_URL}" "${DROPBEAR_SRC_DIR}" || return 1
    make distclean
    ./configure \
        --prefix="${INSTALL_PREFIX}" \
        --enable-static \
        LTM_CFLAGS="${MUSL_CFLAGS}" \
        || return 1
    make || return 1
    make strip || return 1
    make install || return 1
    cd "${BIN_DIR}" && ln -sf "dbclient" "ssh"
    cd "${BIN_DIR}" && ln -sf "dropbearkey" "ssh-keygen"
}

build_bearssl()
{
    clone_cd_rebase "${BEARSSL_URL}" "${BEARSSL_SRC_DIR}" || return 1
    make clean
    make \
        CC="${MUSL_CC}" \
        CFLAGS="${MUSL_CFLAGS}" \
        LD="${MUSL_CC}" \
        LDFLAGS="-static ${MUSL_LDFLAGS}" \
        LDDLL="${MUSL_CC}" \
        LDDLLFLAGS="-shared ${MUSL_LDFLAGS}" \
        || return 1
    install -D -m 644 "${BEARSSL_SRC_DIR}/build/libbearssl.a" "${LIB_DIR}" || return 1
    install -D -m 755 "${BEARSSL_SRC_DIR}/build/brssl" "${BIN_DIR}" || return 1
    cp -r "${BEARSSL_SRC_DIR}/inc/"* "${INCLUDE_DIR}" || return 1
}

build_curl()
{
    get_archive_cd "${CURL_SRC_DIR}" "${CURL_URL}" gz
    make distclean
    cp "${CURL_SRC_DIR}/src/tool_hugehelp.c.cvs" "${CURL_SRC_DIR}/src/tool_hugehelp.c"
    ./configure \
        --prefix="${INSTALL_PREFIX}" \
        --build="${TARGET}" \
        --host="${TARGET}" \
        --with-bearssl \
        --disable-silent-rules \
        LT_SYS_LIBRARY_PATH="${LIB_DIR}" \
        CC="${MUSL_CC}" \
        CFLAGS="${MUSL_CFLAGS}" \
        LDFLAGS="-static --static ${MUSL_LDFLAGS}" \
        || return 1
    make || return 1
    make install || return 1
}

build_git()
{
    clone_cd_rebase "${GIT_URL}" "${GIT_SRC_DIR}" "${GIT_VER}" || return 1
    make distclean
    make \
        V=1 \
        SHELL_PATH="${SHELL}" \
        NO_OPENSSL=YesPlease \
        NO_SVN_TESTS=YesPlease \
        NO_PERL=YesPlease \
        NO_GITWEB=YesPlease \
        NO_PYTHON=YesPlease \
        NO_TCLTK=YesPlease \
        NO_INSTALL_HARDLINKS=YesPlease \
        INSTALL_STRIP="-s" \
        NO_GETTEXT=YesPlease \
        NO_EXPAT=YesPlease \
        NO_REGEX=YesPlease \
        INSTALL_SYMLINKS=YesPlease \
        NO_ICONV=YesPlease \
        SKIP_DASHED_BUILT_INS=YesPlease \
        NO_R_TO_GCC_LINKER=YesPlease \
        CURLDIR="${INSTALL_PREFIX}" \
        prefix="${INSTALL_PREFIX}" \
        CC="${MUSL_CC}" \
        CFLAGS="${MUSL_CFLAGS}" \
        LDFLAGS="-static ${MUSL_LDFLAGS}" \
        EXTLIBS="-lbearssl -lz" \
        strip \
        install \
        || return 1
}

build_binutils()
{
    get_archive_cd "${BINUTILS_SRC_DIR}" "${BINUTILS_URL}" gz
    if [ -f "Makefile" ]
    then
        make distclean
    fi
    rm $(find . -name config.cache)
    ./configure \
        --prefix="${INSTALL_PREFIX}" \
        --with-sysroot="${INSTALL_PREFIX}" \
        --with-build-sysroot="${INSTALL_PREFIX}" \
        --build="${TARGET}" \
        --host="${TARGET}" \
        --target="${TARGET}" \
        --enable-targets="${TARGET}" \
        --enable-relro \
        --disable-nls \
        --disable-gdb \
        --enable-default-hash-style=gnu \
        --enable-gprofng=no \
        --disable-gold \
        --disable-libquadmath \
        --disable-bootstrap \
        --disable-libdecnumber \
        --disable-readline \
        --disable-sim \
        --disable-seperate-code \
        --enable-64-bit-bfd \
        --enable-ld=default \
        --with-system-zlib \
        --enable-objc-gc=no \
        --with-pic \
        --disable-libada \
        --disable-libssp \
        --disable-gcov \
        --disable-plugins \
        --disable-multilib \
        --without-libiconv-prefix \
        --without-msgpack \
        --disable-libstdcxx \
        --enable-new-dtags \
        || return 1
    make MAKEINFO=true || return 1
    make install-strip || return 1
    rm -rf "${INSTALL_PREFIX}/share/info"
}

build_make()
{
    get_archive_cd "${MAKE_SRC_DIR}" "${MAKE_URL}" gz
    if [ -f "Makefile" ]
    then
        make distclean
    fi
    ./configure \
        --prefix="${INSTALL_PREFIX}" \
        --build="${TARGET}" \
        --host="${TARGET}" \
        --disable-nls \
        || return 1
    make || return 1
    make install-strip || return 1
    rm -rf "${INSTALL_PREFIX}/share/info"
}

BUILD_MUSL=0
BUILD_BYACC=0
BUILD_LEX=0
BUILD_ZLIB=0
BUILD_BUSYBOX=0
BUILD_DROPBEAR=0
BUILD_CURL=0
BUILD_BEARSSL=0
BUILD_GIT=0
BUILD_BINUTILS=0
BUILD_MAKE=0

CLEAN_BUILD=0
CLEAN_ROOT=0

POST_CLEAN_BUILD=0

if [ "$#" -eq 0 ]
then
    lilroot_help
    exit 1
fi

while [ "$#" -gt 0 ]
do
    case $1 in
        clean|clean-build)
            CLEAN_BUILD=1
            shift
            ;;
        clean-root)
            CLEAN_ROOT=1
            shift
            ;;
        clean-all|distclean)
            CLEAN_BUILD=1
            CLEAN_ROOT=1
            shift
            ;;
        post-clean)
            POST_CLEAN_BUILD=1
            shift
            ;;
        musl)
            BUILD_MUSL=1
            shift
            ;;
        byacc)
            BUILD_BYACC=1
            shift
            ;;
        lex)
            BUILD_LEX=1
            shift
            ;;
        zlib)
            BUILD_ZLIB=1
            shift
            ;;
        busybox)
            BUILD_BUSYBOX=1
            shift
            ;;
        dropbear)
            BUILD_DROPBEAR=1
            shift
            ;;
        bearssl)
            BUILD_BEARSSL=1
            shift
            ;;
        curl)
            BUILD_CURL=1
            shift
            ;;
        git)
            BUILD_GIT=1
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
        all)
            BUILD_MUSL=1
            BUILD_BYACC=1
            BUILD_LEX=1
            BUILD_ZLIB=1
            BUILD_BUSYBOX=1
            BUILD_DROPBEAR=1
            BUILD_BEARSSL=1
            BUILD_CURL=1
            BUILD_GIT=1
            BUILD_BINUTILS=1
            BUILD_MAKE=1
            shift
            ;;
        help|-h|--help)
            lilroot_help
            exit 0
            ;;
        *)
            echo "Unknown arg $1"
            lilroot_help
            exit 1
            ;;
    esac
done

setup_root

cd "${REPOS_DIR}"

if [ "${CLEAN_BUILD}" -eq 1 ]
then
    clean_build
fi

if [ "${CLEAN_ROOT}" -eq 1 ]
then
    clean_root
fi

export PATH="${BIN_DIR}:${PATH}"
export MKDIR_P="mkdir -p"
export SHELL="$(which sh)"
export CONFIG_SHELL="${SHELL}"
export SED="sed"
export CC="${MUSL_CC}"
if ! command -v "${MUSL_CC}" >/dev/null 2>&1
then
    export CC="${MUSL_BASE_CC}"
fi
export CFLAGS="${MUSL_CFLAGS}"
export CXXFLAGS="${CFLAGS}"
export LIBS="${MUSL_LIBS}"
export LDFLAGS="-static --static ${MUSL_LDFLAGS}"
export LINGUAS=""

if [ "${BUILD_MUSL}" -eq 1 ]
then
    build_musl || exit 1
    export CC="${MUSL_CC}"
fi

if [ "${BUILD_BYACC}" -eq 1 ]
then
    build_byacc || exit 1
fi

if [ "${BUILD_LEX}" -eq 1 ]
then
    build_lex || exit 1
fi

if [ "${BUILD_ZLIB}" -eq 1 ]
then
    build_zlib || exit 1
fi

if [ "${BUILD_BUSYBOX}" -eq 1 ]
then
    build_busybox || exit 1
    export SHELL="$(which sh)"
    export CONFIG_SHELL="${SHELL}"
fi

if [ "${BUILD_DROPBEAR}" -eq 1 ]
then
    build_dropbear || exit 1
fi

if [ "${BUILD_BEARSSL}" -eq 1 ]
then
    build_bearssl || exit 1
fi

if [ "${BUILD_CURL}" -eq 1 ]
then
    build_curl || exit 1
fi

if [ "${BUILD_GIT}" -eq 1 ]
then
    build_git || exit 1
fi

if [ "${BUILD_BINUTILS}" -eq 1 ]
then
    build_binutils || exit 1
fi

if [ "${BUILD_MAKE}" -eq 1 ]
then
    build_make || exit 1
fi

if [ "${POST_CLEAN_BUILD}" -eq 1 ]
then
    clean_build
fi
