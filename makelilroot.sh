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

BASE_URL="https://github.com/Mekapaedia/sbase.git"
BASE_DIR="sbase"
BASE_SRC_DIR="${REPOS_DIR}/${BASE_DIR}"

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

NETBSD_CURSES_URL="https://github.com/sabotage-linux/netbsd-curses.git"
NETBSD_CURSES_DIR="netbsd-curses"
NETBSD_CURSES_SRC_DIR="${REPOS_DIR}/${NETBSD_CURSES_DIR}"

OKSH_URL="https://github.com/Mekapaedia/oksh"
OKSH_DIR="oksh"
OKSH_SRC_DIR="${REPOS_DIR}/${OKSH_DIR}"

ALL_REPOS="${MUSL_SRC_DIR} \
           ${BASE_SRC_DIR} \
           ${BYACC_SRC_DIR} \
           ${LEX_SRC_DIR} \
           ${ZLIB_SRC_DIR} \
           ${DROPBEAR_SRC_DIR} \
           ${BEARSSL_SRC_DIR} \
           ${CURL_SRC_DIR} \
           ${GIT_SRC_DIR} \
           ${BINUTILS_SRC_DIR} \
           ${MAKE_SRC_DIR} \
           ${NETBSD_CURSES_SRC_DIR} \
           ${OKSH_SRC_DIR} \
           "

ALL_ARCHIVES="${BYACC_DIR}.tar ${BYACC_DIR}.tar.gz \
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
    musl, base, byacc, lex, zlib, dropbear, bearssl, curl, git, binutils, make, netbsd-curses, oksh
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
    git pull --rebase --autostash || return 1
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
    COMP_EX="gz"
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
            gzip -d "${ARCHIVE_NAME}" || return 1
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

build_base()
{
    clone_cd_rebase "${BASE_URL}" "${BASE_SRC_DIR}" || return 1
    make clean
    git restore config.mk || return 1
    mv config.mk config.mk.orig
    sed "s|/usr/local|${INSTALL_PREFIX}|" <config.mk.orig >config.mk || return 1
    echo "CC = ${MUSL_CC}" >> config.mk
    echo "LDFLAGS = -static ${MUSL_LDFLAGS}" >> config.mk
    echo "CFLAGS = -static ${MUSL_CFLAGS}" >> config.mk
    make all install || return 1
    ln -sf "${BIN_DIR}/xinstall" "${BIN_DIR}/install"
    echo "#!/bin/sh" > "${BIN_DIR}/bsdtar" || return 1
    echo 'if [ "$#" -lt 1 ]; then tar; exit $?; fi' >> "${BIN_DIR}/bsdtar" || return 1
    echo 'BSDTAR_ARGS="$1"' >> "${BIN_DIR}/bsdtar" || return 1
    echo "shift" >> "${BIN_DIR}/bsdtar" || return 1
    echo 'tar $(echo "${BSDTAR_ARGS}" | sed "s/[^xfcmtjaJZ]//g" | sed "s/[xfcmtjaJZ]/-& /g") $@' >> ${BIN_DIR}/bsdtar || return 1
    chmod +x "${BIN_DIR}/bsdtar" || return 1
}

build_byacc()
{
    get_archive_cd "${BYACC_SRC_DIR}" "${BYACC_URL}"
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
    cp minigzip "${BIN_DIR}"
    cd "${BIN_DIR}" && ln -sf "minigzip" "gzip"
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
    get_archive_cd "${CURL_SRC_DIR}" "${CURL_URL}"
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
    clone_cd_rebase "${GIT_URL}" "${GIT_SRC_DIR}" || return 1
    make distclean
    make \
        V=1 \
        SHELL_PATH="${SHELL}" \
        NO_OPENSSL=1 \
        NO_SVN_TESTS=1 \
        NO_PERL=1 \
        NO_GITWEB=1 \
        NO_PYTHON=1 \
        NO_TCLTK=1 \
        NO_INSTALL_HARDLINKS=1 \
        INSTALL_STRIP="-s" \
        NO_GETTEXT=1 \
        NO_EXPAT=1 \
        NO_REGEX=1 \
        CURLDIR="${INSTALL_PREFIX}" \
        prefix="${INSTALL_PREFIX}" \
        CC="${MUSL_CC}" \
        CFLAGS="${MUSL_CFLAGS}" \
        LDFLAGS="-static ${MUSL_LDFLAGS}" \
        EXTLIBS="-lbearssl -lz" \
        TAR=bsdtar \
        install \
        || return 1
}

build_binutils()
{
    get_archive_cd "${BINUTILS_SRC_DIR}" "${BINUTILS_URL}"
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
        --enable-targets="x86_64-pep" \
        --enable-install-libiberty \
        --enable-install-libbfd \
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
    get_archive_cd "${MAKE_SRC_DIR}" "${MAKE_URL}"
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

build_netbsd_curses()
{
    clone_cd_rebase "${NETBSD_CURSES_URL}" "${NETBSD_CURSES_SRC_DIR}" || return 1
    make clean
    make -f GNUmakefile \
        PREFIX="${INSTALL_PREFIX}" \
        CC="${MUSL_CC}" \
        CFLAGS="${MUSL_CFLAGS}" \
        CFLAGS_HOST="${MUSL_CFLAGS}" \
        LDFLAGS_HOST="-static ${MUSL_LDFLAGS}" \
        LDFLAGS="-static ${MUSL_LDFLAGS}" \
        all-static \
        install-static \
        || return 1
}

build_oksh()
{
    clone_cd_rebase "${OKSH_URL}" "${OKSH_SRC_DIR}" || return 1
    if [ -f "Makefile" ]
    then
        make distclean
    fi
    LDFLAGS="${MUSL_LDFLAGS}" \
    ./configure \
        --prefix="${INSTALL_PREFIX}" \
        --cc="${MUSL_CC}" \
        --cflags="${MUSL_CFLAGS}" \
        --enable-static \
        || return 1
    make || return 1
    make install || return 1
    cd "${BIN_DIR}" && ln -sf "oksh" "sh"
}

BUILD_MUSL=0
BUILD_BASE=0
BUILD_BYACC=0
BUILD_LEX=0
BUILD_ZLIB=0
BUILD_DROPBEAR=0
BUILD_CURL=0
BUILD_BEARSSL=0
BUILD_GIT=0
BUILD_BINUTILS=0
BUILD_MAKE=0
BUILD_NETBSD_CURSES=0
BUILD_OKSH=0

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
        base)
            BUILD_BASE=1
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
            BUILD_BYACC=1
            BUILD_LEX=1
            BUILD_ZLIB=1
            BUILD_DROPBEAR=1
            BUILD_BEARSSL=1
            BUILD_CURL=1
            BUILD_GIT=1
            BUILD_BINUTILS=1
            BUILD_MAKE=1
            BUILD_NETBSD_CURSES=1
            BUILD_OKSH=1
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

export PATH="${BIN_DIR}:${PATH}"
export MKDIR_P="mkdir -p"
export SHELL="$(which sh)"
export CONFIG_SHELL="${SHELL}"
export SED="sed"
export CC="${MUSL_CC}"
if ! "${MUSL_CC}" --version 2>&1 >/dev/null
then
    export CC="${MUSL_BASE_CC}"
fi
export CFLAGS="${MUSL_CFLAGS}"
export CXXFLAGS="${CFLAGS}"
export LIBS="${MUSL_LIBS}"
export LDFLAGS="-static --static ${MUSL_LDFLAGS}"
export LINGUAS=""

if [ "${CLEAN_BUILD}" -eq 1 ]
then
    clean_build
fi

if [ "${CLEAN_ROOT}" -eq 1 ]
then
    clean_root
fi

if [ "${BUILD_MUSL}" -eq 1 ]
then
    build_musl || exit 1
    export CC="${MUSL_CC}"
fi

if [ "${BUILD_BASE}" -eq 1 ]
then
    build_base || exit 1
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

if [ "${BUILD_NETBSD_CURSES}" -eq 1 ]
then
    build_netbsd_curses || exit 1
fi

if [ "${BUILD_OKSH}" -eq 1 ]
then
    build_oksh || exit 1
    export SHELL="$(which sh)"
    export CONFIG_SHELL="${SHELL}"
fi

if [ "${POST_CLEAN_BUILD}" -eq 1 ]
then
    clean_build
fi
