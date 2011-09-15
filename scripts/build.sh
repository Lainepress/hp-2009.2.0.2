#!/bin/sh

# A script to build the haskell platform.

# It works by...
# It expects to be run...

die () {
  echo
  echo "Error:"
  echo $1 >&2
  exit 2
}

[ -f "scripts/config" ] \
  || die "Please run ./configure first"

. scripts/config

# also check GHC, GHC_PKG
[ -n "$prefix" ] \
  || die "Expected prefix to have been defined in scripts/config"

CABAL_PKG_VER="`grep Cabal packages/core.packages`"
[ -n "${CABAL_PKG_VER}" ] \
  || die "Expected Cabal as a preinstalled package"
if test "${ALLOW_UNSUPPORTED_GHC}" = "YES"; then
CABAL_PKG_VER="Cabal"
fi

HAPPY_PKG_VER="`grep happy packages/platform.packages`"
HAPPY_INPLACE="${HAPPY_PKG_VER}/dist/build/happy/happy"
HAPPY_TEMPLATE="${HAPPY_PKG_VER}"

ALEX_PKG_VER="`grep alex packages/platform.packages`"
ALEX_INPLACE="${ALEX_PKG_VER}/dist/build/alex/alex"

CABAL_INSTALL_PKG_VER="`grep cabal-install packages/platform.packages`"
CABAL_INSTALL_INPLACE="${CABAL_INSTALL_PKG_VER}/dist/build/cabal/cabal"

# Initialise the package db
PACKAGE_DB="packages/package.conf.inplace"
[ -f "${PACKAGE_DB}" ] && rm "${PACKAGE_DB}"
echo '[]' > "${PACKAGE_DB}"

# Maybe use a small script instead ? Tested with bash and zsh.
tell() {
  # Save and shift the executable name
  CMD=$1
  shift
  # Build the string of command-line parameters
  PRINT="\"${CMD}\""
  for arg in "$@"; do
      PRINT="${PRINT} \"${arg}\""
  done
  # Echo the command
  echo `echo $PRINT`
  # Run the command
  "$CMD" "$@"
}

build_pkg () {
  PKG=$1

  cd "${PKG}" 2> /dev/null \
    || die "The directory for the component ${PKG} is missing"

  [ -f Setup ] && rm Setup

  tell ${GHC} --make Setup -o Setup -package "${CABAL_PKG_VER}" \
    || die "Compiling the Setup script failed"
  [ -x Setup ] || die "The Setup script does not exist or cannot be run"

  if [ -x ../${HAPPY_INPLACE} ]; then
    HAPPY_FLAG1="--with-happy=../${HAPPY_INPLACE}"
    HAPPY_FLAG2="--happy-options=--template=../${HAPPY_TEMPLATE}"
  fi
  if [ -x ../${ALEX_INPLACE} ]; then
    ALEX_FLAG="--with-alex=../${ALEX_INPLACE}"
  fi
  if [ -x ../${CABAL_INSTALL_INPLACE} ]; then
    CABAL_INSTALL_FLAG="--with-cabal-install=../${CABAL_INSTALL_INPLACE}"
  fi
  if test "${ENABLE_PROFILING}" = "YES"; then
    CABAL_PROFILING_FLAG="--enable-library-profiling"
  fi


  tell ./Setup configure --package-db="../../${PACKAGE_DB}" --prefix="${prefix}" \
    --with-compiler=${GHC} --with-hc-pkg=${GHC_PKG} --with-hsc2hs=${HSC2HS} \
    ${HAPPY_FLAG1} ${HAPPY_FLAG2} ${ALEX_FLAG} \
    ${CABAL_INSTALL_FLAG} ${CABAL_PROFILING_FLAG} \
    ${EXTRA_CONFIGURE_OPTS} ${VERBOSE} \
    || die "Configuring the ${PKG} package failed"

  tell ./Setup build ${VERBOSE} \
    || die "Building the ${PKG} package failed"

  tell ./Setup register --inplace ${VERBOSE} \
    || die "Registering the ${PKG} package failed"

  cd ..
}

# Is this exact version of the package already installed?
is_pkg_installed () {
  PKG_VER=$1
  grep " ${PKG_VER} " installed.packages > /dev/null 2>&1
}

# Actually do something!

cd packages
for pkg in `cat platform.packages`; do
  if is_pkg_installed "${pkg}"; then
    echo "Platform package ${pkg} is already installed. Skipping..."
  else
    echo "Building ${PKG}"
    build_pkg "${pkg}"
  fi
done

echo
echo '**************************************************'
echo '* Building each component completed successfully. '
echo '*                                                 '
if test "${USER_INSTALL}" = "YES"; then
echo '* Now do "make install"                           '
else
echo '* Now do "sudo make install"                      '
fi
echo '**************************************************'
