#!/bin/sh
# Configure and build linphone-sdk + linphone-desktop against the system libraries.
# Run inside the packaging/Dockerfile image from the repository root; the result
# is installed into build/OUTPUT. Re-running continues where it stopped.
#   packaging/build.sh                 (JOBS=n to limit parallel jobs)
#   CONFIGURE_ONLY=1 packaging/build.sh
set -eu
ROOT=$(cd "$(dirname "$0")/.." && pwd)
BUILD=${BUILD_DIR:-$ROOT/build}
OFF=""
for x in AOM BV16 CODEC2 DAV1D DECAF FFMPEG GSM HIDAPI JSONCPP LIBJPEGTURBO LIBSRTP2 LIBVPX \
         LIBXML2 LIBYUV MBEDTLS OPENSSL OPENCORE_AMR OPENH264 OPENLDAP OPUS RNNOISE SOCI SPEEX \
         SQLITE3 VO_AMRWBENC XERCESC ZLIB ZXINGCPP; do OFF="$OFF -DBUILD_$x=OFF"; done
# shellcheck disable=SC2086
[ -f "$BUILD/build.ninja" ] || cmake -S "$ROOT" -B "$BUILD" -G Ninja \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DENABLE_CRASH_HANDLER=OFF -DENABLE_UPDATE_CHECK=OFF -DENABLE_PQCRYPTO=ON -DENABLE_AV1=OFF \
    -DENABLE_BV16=OFF -DENABLE_TESTS=OFF -DENABLE_UNIT_TESTS=OFF -DENABLE_TESTS_COMPONENTS=OFF \
    -DENABLE_DOC=OFF -DENABLE_QT_KEYCHAIN=OFF -DENABLE_APP_PACKAGING=OFF $OFF
[ -n "${CONFIGURE_ONLY:-}" ] && exit 0
cmake --build "$BUILD" -j"${JOBS:-$(nproc)}"
cmake --install "$BUILD"
