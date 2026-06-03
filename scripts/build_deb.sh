#!/bin/bash
set -e

# Change directory to the root of the project (parent of scripts/)
cd "$(dirname "$0")/.."

# 1. Parse flavor argument
TARGET_FLAVOR=$1
if [ -z "$TARGET_FLAVOR" ]; then
  TARGET_FLAVOR="all"
fi

if [ "$TARGET_FLAVOR" = "all" ]; then
  FLAVORS=("dev" "staging" "prod")
elif [ "$TARGET_FLAVOR" = "dev" ] || [ "$TARGET_FLAVOR" = "staging" ] || [ "$TARGET_FLAVOR" = "prod" ]; then
  FLAVORS=("$TARGET_FLAVOR")
else
  echo "Error: Unknown environment flavor '$TARGET_FLAVOR'."
  echo "Usage: $0 [dev|staging|prod|all]"
  exit 1
fi

echo "=========================================="
echo "Building Fletch Linux Debian Packages"
echo "Target: $TARGET_FLAVOR"
echo "=========================================="

# Extract version from pubspec.yaml
VERSION=$(grep 'version:' pubspec.yaml | head -n 1 | awk '{print $2}' | cut -d '+' -f 1)
echo "App Version detected: $VERSION"

for f in "${FLAVORS[@]}"; do
  echo "----------------------------------------"
  echo "Processing environment: $f"
  echo "----------------------------------------"

  # Map configuration variables per flavor
  if [ "$f" = "prod" ]; then
    PKG_NAME="fletch"
    APP_DISPLAY_NAME="Fletch"
    BINARY_SUFFIX=""
    INSTALL_DIR="fletch"
    ICON_NAME="fletch"
    ICON_FILE="fletch.png"
  elif [ "$f" = "staging" ]; then
    PKG_NAME="fletch-staging"
    APP_DISPLAY_NAME="Fletch Staging"
    BINARY_SUFFIX="_staging"
    INSTALL_DIR="fletch_staging"
    ICON_NAME="fletch_staging"
    ICON_FILE="fletch_staging.png"
  else
    # dev
    PKG_NAME="fletch-dev"
    APP_DISPLAY_NAME="Fletch Dev"
    BINARY_SUFFIX="_dev"
    INSTALL_DIR="fletch_dev"
    ICON_NAME="fletch_dev"
    ICON_FILE="fletch_dev.png"
  fi

  # 1. Build the Linux executable
  echo "Building Linux application for $f..."
  FLAVOR=$f flutter build linux --release --dart-define=FLAVOR=$f

  # 2. Setup staging directory
  STAGING_DIR="build/debian_$f"
  echo "Setting up staging directory $STAGING_DIR..."
  rm -rf "$STAGING_DIR"
  mkdir -p "$STAGING_DIR/DEBIAN"
  mkdir -p "$STAGING_DIR/usr/bin"
  mkdir -p "$STAGING_DIR/usr/lib/$INSTALL_DIR"
  mkdir -p "$STAGING_DIR/usr/share/applications"
  mkdir -p "$STAGING_DIR/usr/share/pixmaps"

  # 3. Copy build bundle to target folder
  echo "Copying assets to /usr/lib/$INSTALL_DIR..."
  cp -r build/linux/x64/release/bundle/* "$STAGING_DIR/usr/lib/$INSTALL_DIR/"

  # 4. Create launcher wrapper script
  echo "Creating launcher /usr/bin/fletch$BINARY_SUFFIX..."
  cat << EOF > "$STAGING_DIR/usr/bin/fletch$BINARY_SUFFIX"
#!/bin/bash
exec /usr/lib/$INSTALL_DIR/fletch "\$@"
EOF

  # 5. Create desktop entry file
  echo "Creating desktop entry..."
  cat << EOF > "$STAGING_DIR/usr/share/applications/fletch$BINARY_SUFFIX.desktop"
[Desktop Entry]
Version=1.0
Type=Application
Name=$APP_DISPLAY_NAME
Comment=Open source HTTP client ($f environment). No Electron. No Node. No browser.
Exec=fletch$BINARY_SUFFIX
Icon=$ICON_NAME
Terminal=false
Categories=Development;Utility;
StartupWMClass=com.example.fletch$BINARY_SUFFIX
EOF

  # 6. Copy icon
  echo "Copying application icon..."
  cp "assets/icon/$ICON_FILE" "$STAGING_DIR/usr/share/pixmaps/$ICON_NAME.png"

  # 7. Create Debian control file
  echo "Creating control configuration..."
  cat << EOF > "$STAGING_DIR/DEBIAN/control"
Package: $PKG_NAME
Version: $VERSION
Section: devel
Priority: optional
Architecture: amd64
Maintainer: Igor <gk_igor_dev@example.com>
Depends: libc6, libgtk-3-0, libglib2.0-0
Description: Fletch HTTP client - $APP_DISPLAY_NAME
 Fletch is a fast, native, open-source HTTP client built with Flutter.
 This is the package for the $APP_DISPLAY_NAME environment.
EOF

  # 8. Set correct file permissions
  echo "Setting system file permissions..."
  chmod -R 755 "$STAGING_DIR"
  chmod 755 "$STAGING_DIR/usr/bin/fletch$BINARY_SUFFIX"
  chmod 644 "$STAGING_DIR/DEBIAN/control"
  chmod 644 "$STAGING_DIR/usr/share/applications/fletch$BINARY_SUFFIX.desktop"
  chmod 644 "$STAGING_DIR/usr/share/pixmaps/$ICON_NAME.png"

  # 9. Build Debian package
  DEB_FILE="build/${PKG_NAME}_${VERSION}_amd64.deb"
  echo "Packaging debian installer to $DEB_FILE..."
  dpkg-deb --build "$STAGING_DIR" "$DEB_FILE"

  # 10. Cleanup staging
  echo "Cleaning up staging directory..."
  rm -rf "$STAGING_DIR"

  echo "Finished packaging environment: $f"
done

echo "=========================================="
echo "Debian Package packaging finished successfully!"
echo "Outputs:"
for f in "${FLAVORS[@]}"; do
  if [ "$f" = "prod" ]; then
    echo "  - build/fletch_${VERSION}_amd64.deb"
  elif [ "$f" = "staging" ]; then
    echo "  - build/fletch-staging_${VERSION}_amd64.deb"
  else
    echo "  - build/fletch-dev_${VERSION}_amd64.deb"
  fi
done
echo "=========================================="
