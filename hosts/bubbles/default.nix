{ ... }:

{
  networking.hostName = "bubbles";

  # BlueBubbles and nothing else: this host runs explicitly low-powered.
  system.activationScripts.bubblesLowPower.text = ''
    /usr/bin/pmset -c lowpowermode 1
  '';
}
