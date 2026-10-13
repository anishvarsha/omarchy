#!/bin/bash

source "$(dirname "$0")/base-test.sh"

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/hyprctl" <<'BASH'
#!/bin/bash

if [[ $1 == "activeworkspace" && $2 == "-j" ]]; then
  printf '{"id":3,"tiledLayout":"%s"}\n' "${HYPR_TILED_LAYOUT:-dwindle}"
  exit 0
fi

if [[ $1 == "dispatch" ]]; then
  printf '%s\n' "$*" >>"$HYPRCTL_LOG"
  exit 0
fi

exit 1
BASH
chmod +x "$tmpdir/hyprctl"

log="$tmpdir/hyprctl.log"
PATH="$tmpdir:$PATH" HYPRCTL_LOG="$log" HYPR_TILED_LAYOUT=dwindle \
  "$ROOT/bin/omarchy-hyprland-window-split-toggle"

grep -Fq 'hl.dsp.layout("togglesplit")' "$log" ||
  fail "window split toggles the split on a dwindle workspace"
pass "window split toggles the split on a dwindle workspace"

>"$log"
PATH="$tmpdir:$PATH" HYPRCTL_LOG="$log" HYPR_TILED_LAYOUT=scrolling \
  "$ROOT/bin/omarchy-hyprland-window-split-toggle"

[[ -s $log ]] &&
  fail "window split stays silent on a scrolling workspace"
pass "window split stays silent on a scrolling workspace"