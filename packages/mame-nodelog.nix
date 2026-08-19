# MAME with per-node CSV logging on Donkey Kong's jump chain, for
# phosphor-emulator's discrete sound work (…-discrete-node-compare-2b7f).
#
# A DIAGNOSTIC build: it writes one CSV row per sample for the whole run, so it
# is slower than stock MAME and drops a ~12 MB file in the working directory.
# Deliberately a standalone package — it should never end up in a profile.
{
  lib,
  mame,
  SDL2,
  SDL2_ttf,
  sdl3,
  sdl3-ttf,
}:

let
  # The five nodes of the jump chain, and what each is in dkong_sound.rs:
  #
  #   NODE_28  control voltage, after the slew capacitor   JUMP_CV
  #   NODE_29  555 square, before the envelope             JUMP_555
  #   NODE_35  envelope capacitor, before its diode        JUMP_LID
  #   NODE_38  diode mixer: envelope and square combined   JUMP_MIX
  #   NODE_39  emitter follower, before the divider        JUMP_INT
  anchor = "DISCRETE_MULTIPLY(DS_OUT_SOUND1,NODE_39,DK_R25/(DK_R26+DK_R25))";
  csvlog = "DISCRETE_CSVLOG5(NODE_28, NODE_29, NODE_35, NODE_38, NODE_39)";
in
mame.overrideAttrs (old: {
  pname = "mame-nodelog";

  # Same SDL3 swap as mameOverlay in lib/mkHost.nix, kept in step on purpose:
  # this build is only useful if it is the stock one plus the logging.
  buildInputs = (builtins.filter (p: p != SDL2 && p != SDL2_ttf) old.buildInputs) ++ [
    sdl3
    sdl3-ttf
  ];
  makeFlags = old.makeFlags ++ [ "OSD=sdl3" ];

  # Placed after the last node it reads, inside the jump task, so each row holds
  # that step's values. --replace-fail so a source change breaks the build
  # loudly instead of producing a MAME that silently logs nothing.
  postPatch = (old.postPatch or "") + ''
    substituteInPlace src/mame/nintendo/dkong_a.cpp \
      --replace-fail '${anchor}' '${anchor}
      ${csvlog}'
  '';

  meta = old.meta // {
    description = "MAME with discrete node logging on Donkey Kong's jump chain";
    mainProgram = "mame";
  };
})
