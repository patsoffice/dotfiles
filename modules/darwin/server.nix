{ username, ... }:

{
  # ── Power: always-on server, display may sleep ─────────────────────
  power.sleep = {
    computer = "never";
    display = 10;
  };

  # pmset extras nix-darwin has no native options for: wake on network
  # access, don't sleep while an SSH session is active, and restart
  # automatically after a power failure. All idempotent across switches.
  system.activationScripts.serverPower.text = ''
    /usr/bin/pmset -c womp 1
    /usr/bin/pmset -c ttyskeepawake 1
    /usr/bin/pmset -c autorestart 1
  '';

  # ── Dock: minimal, VNC sessions only ───────────────────────────────
  # This list replaces the default set on activation.
  system.defaults.dock = {
    persistent-apps = [
      "/System/Library/CoreServices/Finder.app"
      "/System/Applications/System Settings.app"
    ];
    persistent-others = [ ];
  };

  # ── Remote access: SSH + Screen Sharing, LAN only ───────────────────
  # No native nix-darwin options exist for these; systemsetup/kickstart
  # are idempotent so re-running them on every switch is safe.
  # VNC serves the FileVault/login screen when nobody is logged in, and
  # SSH doubles as the remote FileVault unlock path.
  system.activationScripts.remoteAccess.text = ''
    /usr/sbin/systemsetup -setremotelogin on
    /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart \
      -activate -configure -access -on -users ${username} -privs -all -restart -agent
  '';
}
