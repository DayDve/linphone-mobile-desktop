#!/bin/sh
# Package the packaging/build.sh result (build/OUTPUT) as linphone-mobile, installed into /opt/linphone.
#   packaging/make-deb.sh [VERSION]   -> build/linphone-mobile_<version>_<arch>.deb
#
# - takes only what is needed to run (no headers, cmake files or test libraries);
# - strips debug info;
# - makes library paths relative (RUNPATH $ORIGIN): in the build tree they point into
#   build/OUTPUT, and Linphone writes its own path into ~/.config/autostart, so it has to
#   start without an LD_LIBRARY_PATH wrapper.
set -eu
ROOT=$(cd "$(dirname "$0")/.." && pwd)
BUILD=${BUILD_DIR:-$ROOT/build}
OUT=$BUILD/OUTPUT
STAGE=$BUILD/deb
PREFIX=/opt/linphone
NAME=linphone-mobile
ARCH=$(dpkg --print-architecture)
DESC=$(git -C "$ROOT" describe --tags 2>/dev/null || echo unknown)   # 6.2.4-12-g15d6198
VER=${1:-$(echo "$DESC" | sed -E 's/^([0-9.]+)-([0-9]+)-g([0-9a-f]+)$/\1+mobile\2.g\3/; s/^([0-9.]+)$/\1+mobile0/')}
DEB=$BUILD/${NAME}_${VER}_$ARCH.deb

[ -x "$OUT/bin/linphone" ] || { echo "No $OUT/bin/linphone: run packaging/build.sh first"; exit 1; }
command -v patchelf >/dev/null || { echo "patchelf is needed"; exit 1; }

rm -rf "$STAGE"
D=$STAGE$PREFIX
mkdir -p "$D/bin" "$D/lib" "$D/share" "$STAGE/DEBIAN" "$STAGE/usr/bin" \
         "$STAGE/usr/share/applications" "$STAGE/usr/share/icons/hicolor/scalable/apps"

# 1. Files
cp "$OUT/bin/linphone" "$D/bin/"
for f in "$OUT"/lib/*.so.*; do
    case "${f##*/}" in libbctoolbox-tester.so*|libbcunit.so*) continue ;; esac
    cp -P "$f" "$D/lib/"
done
mkdir -p "$D/lib/mediastreamer/plugins" "$D/lib/liblinphone/plugins"
cp "$OUT"/lib/mediastreamer/plugins/*.so "$D/lib/mediastreamer/plugins/" 2>/dev/null || true
cp "$OUT"/lib/liblinphone/plugins/*.so "$D/lib/liblinphone/plugins/" 2>/dev/null || true
# belr: SIP/SDP grammars, fatal without them
cp -r "$OUT/share/linphone" "$OUT/share/sounds" "$OUT/share/images" "$OUT/share/belr" "$D/share/"

# 2. strip and RUNPATH
for f in "$D/bin/linphone" "$D"/lib/*.so.* "$D"/lib/*/plugins/*.so; do
    [ -f "$f" ] && [ ! -L "$f" ] || continue
    strip --strip-unneeded "$f"
    case "$f" in
        */bin/*) patchelf --set-rpath '$ORIGIN/../lib' "$f" ;;
        */plugins/*) patchelf --set-rpath '$ORIGIN/../..' "$f" ;;
        *) patchelf --set-rpath '$ORIGIN' "$f" ;;
    esac
done

# 3. Launcher, desktop entry, icon
ln -s "$PREFIX/bin/linphone" "$STAGE/usr/bin/linphone"
install -m644 "$ROOT/Linphone/data/image/logo.svg" \
    "$STAGE/usr/share/icons/hicolor/scalable/apps/linphone.svg"
cat > "$STAGE/usr/share/applications/linphone.desktop" <<EOD
[Desktop Entry]
Name=Linphone
GenericName=SIP Phone
Comment=A libre SIP client
Type=Application
Exec=$PREFIX/bin/linphone %u
Icon=linphone
Terminal=false
Categories=Network;Telephony;
MimeType=x-scheme-handler/sip-linphone;x-scheme-handler/sips-linphone;x-scheme-handler/linphone-sip;x-scheme-handler/linphone-sips;x-scheme-handler/sip;x-scheme-handler/sips;x-scheme-handler/tel;x-scheme-handler/callto;x-scheme-handler/linphone-config;
X-PulseAudio-Properties=media.role=phone
X-KDE-Wayland-Interfaces=kde_lockscreen_overlay_v1
EOD

# 4. Dependencies on system libraries (Qt 6 and the rest)
mkdir -p "$STAGE/debian"
printf 'Source: %s\n\nPackage: %s\nArchitecture: %s\n' $NAME $NAME "$ARCH" > "$STAGE/debian/control"
DEPS=$(cd "$STAGE" && find opt -type f \( -name '*.so*' -o -path '*/bin/*' \) |
       xargs dpkg-shlibdeps -O -l"$D/lib" --ignore-missing-info 2>/dev/null | sed 's/^shlibs:Depends=//')
rm -rf "$STAGE/debian"
[ -n "$DEPS" ] || { echo "dpkg-shlibdeps found no dependencies"; exit 1; }

SIZE=$(du -sk "$STAGE" | cut -f1)
cat > "$STAGE/DEBIAN/control" <<EOD
Package: $NAME
Version: $VER
Architecture: $ARCH
Maintainer: DayDve <daydve@smbit.pro>
Installed-Size: $SIZE
Depends: $DEPS
Conflicts: linphone-desktop, linphone-tune
Replaces: linphone-tune
Section: comm
Priority: optional
Homepage: https://github.com/DayDve/linphone-mobile-desktop
Description: Linphone Desktop $DESC for Plasma Mobile
 Linphone Desktop with a phone layout and Plasma Mobile integration: calls
 above the lock screen, notifications for messages and missed calls, starting
 minimized. Installed into $PREFIX.
EOD

dpkg-deb --root-owner-group -Zxz --build "$STAGE" "$DEB" >/dev/null
echo "Built: $DEB ($(du -h "$DEB" | cut -f1))"
