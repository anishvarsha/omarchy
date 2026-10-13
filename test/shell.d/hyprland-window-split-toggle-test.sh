#!/bin/bash

source "$(dirname "$0")/base-test.sh"

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/hyprctl" <<'BASH'
#!/bin/bash

if [[ $1 == "eval" ]]; then
  printf '%s\n' "$2" >>"$HYPRCTL_LOG"
  exit "${HYPR_EVAL_STATUS:-0}"
fi

exit 1
BASH
chmod +x "$tmpdir/hyprctl"

log="$tmpdir/hyprctl.log"

PATH="$tmpdir:$PATH" HYPRCTL_LOG="$log" \
  "$ROOT/bin/omarchy-hyprland-window-split-toggle" ||
  fail "window split toggle succeeds on a Lua configuration root"

grep -Fq 'hl.get_active_workspace()' "$log" ||
  fail "window split toggle reads the active workspace layout"
grep -Fq 'workspace.tiled_layout == "dwindle"' "$log" ||
  fail "window split toggle checks the layout before toggling"
grep -Fq 'hl.dispatch(hl.dsp.layout("togglesplit"))' "$log" ||
  fail "window split toggle dispatches the split in the guarded Lua call"
pass "window split toggle checks the layout and toggles it in one Lua call"

PATH="$tmpdir:$PATH" HYPRCTL_LOG="$log" HYPR_EVAL_STATUS=1 \
  "$ROOT/bin/omarchy-hyprland-window-split-toggle" 2>/dev/null
(( $? != 0 )) ||
  fail "window split toggle reports a failed Lua dispatch"
pass "window split toggle reports a failed Lua dispatch"