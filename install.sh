#!/bin/zsh
# Compiles the brightness tool and installs a LaunchAgent so idledim runs at login.
set -e
DIR="${0:A:h}"
LABEL="io.ruiying.idledim"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"

echo "Compiling brightness…"
swiftc -O "$DIR/brightness.swift" -o "$DIR/brightness"
chmod +x "$DIR/idledim.sh"

echo "Current brightness: $("$DIR/brightness")"

mkdir -p "$HOME/Library/LaunchAgents"
cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>$LABEL</string>
  <key>ProgramArguments</key>
  <array><string>$DIR/idledim.sh</string></array>
  <key>EnvironmentVariables</key>
  <dict>
    <key>WARN_LIMIT</key><string>120</string>
  </dict>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><true/>
  <key>StandardOutPath</key><string>/tmp/idledim.log</string>
  <key>StandardErrorPath</key><string>/tmp/idledim.log</string>
</dict>
</plist>
EOF

launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$PLIST"
echo "Installed. Log: /tmp/idledim.log"
echo "Uninstall: launchctl bootout gui/\$(id -u)/$LABEL && rm $PLIST"
