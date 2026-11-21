#!/bin/sh
# Assign network IRQs to specific CPUs per smartwrt-irq config.
#
# Wired IRQs match eth_pattern; radios resolve from
# /sys/class/ieee80211/*/device/irq, optionally overridden by wifi_pattern.
# Placement unit is the finest cache group private to a subset of CPUs; on
# single-CPU-route platforms (MIPS GIC) each IRQ goes to a distinct CPU.
#
# Modes:
#   manual  pin every discovered IRQ; irqbalance must not run
#   mixed   pin discovered IRQs, ban them for irqbalance which balances the rest
#   auto    hand every IRQ to irqbalance (init script)
#   off     leave everything to the kernel
#
# Override PROC_ROOT / SYS_ROOT to run outside the device.

set -u

TAG=smartwrt-irq
PINNED=/tmp/run/smartwrt-irq/pinned
PROC_ROOT=${PROC_ROOT:-/proc}
SYS_ROOT=${SYS_ROOT:-/sys}

log() { logger -t "$TAG" -- "$@" 2>/dev/null; return 0; }
dbg() { [ "${SMARTWRT_DEBUG:-0}" = 1 ] && logger -t "$TAG" -- "$@" 2>/dev/null; return 0; }

load_policy() {
	# functions.sh is not nounset-clean; suspend it for the parse only.
	set +u
	IPKG_INSTROOT="${IPKG_INSTROOT:-}"
	. "${UCI_LIB:-/lib/functions.sh}"
	config_load smartwrt-irq || return 1
	config_get SMARTWRT_MODE policy mode manual
	config_get SMARTWRT_ETH_PAT policy eth_pattern eth
	config_get SMARTWRT_WIFI_PAT policy wifi_pattern ""
	config_get SMARTWRT_ETH_CPU policy eth_cpu ""
	config_get SMARTWRT_TIMEOUT policy timeout 30
	# list-type options iterate above; expand_list normalizes the commas
	SMARTWRT_WIFI_CPUS=""
	_add() { SMARTWRT_WIFI_CPUS="$SMARTWRT_WIFI_CPUS $1"; }
	config_list_foreach policy wifi_cpu _add
	[ -n "$SMARTWRT_WIFI_CPUS" ] || config_get SMARTWRT_WIFI_CPUS policy wifi_cpu ""
	set -u
	return 0
}

# Split "0,2-3 x y" style input into one CPU per word.
expand_list() {
	_out=""; _oldIFS=$IFS; IFS=','
	for _p in $1; do
		case $_p in
		*-*)
			_i=${_p%%-*}; _e=${_p##*-}
			while [ "$_i" -le "$_e" ] 2>/dev/null; do
				_out="$_out $_i"; _i=$((_i + 1))
			done ;;
		'') : ;;
		*) _out="$_out $_p" ;;
		esac
	done
	IFS=$_oldIFS
	echo $_out
}

online_cpus() {
	_f="$SYS_ROOT/devices/system/cpu/online"
	[ -r "$_f" ] && expand_list "$(cat "$_f")" || echo 0
}

# Finest cache group per CPU: an L1 pair on MIPS SMT, a singleton elsewhere.
# Groups shared by all online CPUs are skipped.
compute_cache_groups() {
	_n=$(set -- $(online_cpus); echo $#)
	for _c in $(online_cpus); do
		_best=""; _bn=0
		for _d in "$SYS_ROOT/devices/system/cpu/cpu$_c/cache"/index*; do
			_l="$_d/shared_cpu_list"
			[ -r "$_l" ] || continue
			_s=$(expand_list "$(cat "$_l")")
			[ -z "$_s" ] && continue
			_k=$(set -- $_s; echo $#)
			[ "$_k" -ge "$_n" ] && continue
			if [ "$_k" -gt "$_bn" ]; then
				_best=$(echo $_s | tr ' ' '\n' | sort -n | tr '\n' ' ')
				_bn=$_k
			fi
		done
		if [ -n "$_best" ]; then
			echo "${_best% }"
		else
			_s="$SYS_ROOT/devices/system/cpu/cpu$_c/topology/thread_siblings_list"
			[ -r "$_s" ] && expand_list "$(cat "$_s")" || echo "$_c"
		fi
	done | awk '!seen[$0]++'
}

filter_online() {
	_out=""
	for _c in $(expand_list "$1"); do
		case " $CPUS_ONLINE " in *" $_c "*) _out="$_out $_c" ;; esac
	done
	echo ${_out# }
}

eth_irqs() {
	awk -v pat="$SMARTWRT_ETH_PAT" '
		$1 ~ /^[[:space:]]*[0-9]+:/ { sub(/:.*/, "", $1); gsub(/[[:space:]]/, "", $1); if ($NF ~ pat) print $1 }
	' "$PROC_ROOT/interrupts"
}

# One IRQ per radio, sorted by phy name so placement is stable across boots.
wifi_irqs() {
	if [ -n "$SMARTWRT_WIFI_PAT" ]; then
		awk -v pat="$SMARTWRT_WIFI_PAT" '
			$1 ~ /^[[:space:]]*[0-9]+:/ { sub(/:.*/, "", $1); gsub(/[[:space:]]/, "", $1); if ($NF ~ pat) print $1 " pat" }
		' "$PROC_ROOT/interrupts"
		return 0
	fi
	[ -d "$SYS_ROOT/class/ieee80211" ] || return 0
	for _p in "$SYS_ROOT"/class/ieee80211/*; do
		_d=$(readlink -f "$_p/device" 2>/dev/null)
		[ -n "$_d" ] && [ -r "$_d/irq" ] || continue
		_i=$(cat "$_d/irq")
		[ "${_i:-0}" -gt 0 ] 2>/dev/null || continue
		echo "$_i"
	# several phys can share one device; keep the first, dedup by IRQ
	done | sort -u | awk '{ print $1 " phy" NR }'
}

pick_eth_cpu() {
	if [ -n "$SMARTWRT_ETH_CPU" ]; then
		_ok=$(filter_online "$SMARTWRT_ETH_CPU")
		[ -n "$_ok" ] && { set -- $_ok; echo "$1"; return; }
		log "eth_cpu '$SMARTWRT_ETH_CPU' offline; falling back to auto"
	fi
	set -- $CACHE_GROUPS; echo "${1:-$(online_cpus)}"
}

group_of() {
	echo "$CACHE_GROUPS" | awk -v c="$1" '{ for (i = 1; i <= NF; i++) if ($i == c) { print NR; exit } }'
}

pick_wifi_cpus() {
	if [ -n "${SMARTWRT_WIFI_CPUS:-}" ] && [ "$SMARTWRT_WIFI_CPUS" != " " ]; then
		_ok=$(filter_online "$SMARTWRT_WIFI_CPUS")
		[ -n "$_ok" ] && { echo ${_ok# }; return; }
		log "wifi_cpu '$SMARTWRT_WIFI_CPUS' offline; falling back to auto"
	fi
	# prefer one whole free cache group per radio; spill into second threads
	# once groups run out
	_egroup=$(group_of "$(pick_eth_cpu)")
	_groups=$(echo "$CACHE_GROUPS" | while read -r _l; do
		set -- $_l
		[ "$(group_of $1)" = "$_egroup" ] || echo "$_l"
	done)
	# Transpose: first CPU of every group, then second CPU of every group...
	echo "${_groups# }" | awk '
		{
			rows++; for (i = 1; i <= NF; i++) cell[i, rows] = $i
			if (NF > cols) cols = NF
		}
		END {
			for (k = 1; k <= cols; k++)
				for (r = 1; r <= rows; r++)
					if (cell[k, r] != "") printf "%s ", cell[k, r]
		}' | { read -r _pool && [ -n "$_pool" ] && echo ${_pool# } || pick_eth_cpu; }
}

assign_one() {
	_irq=$1; _cpu=$2
	_l="$PROC_ROOT/irq/$_irq/smp_affinity_list"
	[ -e "$PROC_ROOT/irq/$_irq" ] || { log "irq $_irq: gone"; return 1; }
	[ -w "$_l" ] || { log "irq $_irq: not writable"; return 1; }
	# effective_affinity_list reports where the IRQ last fired, not the full
	# mask; trust the mask
	if [ "$(expand_list "$(cat "$_l" 2>/dev/null)")" = "$_cpu" ]; then
		dbg "irq $_irq already on cpu $_cpu"
		return 0
	fi
	_eff="$PROC_ROOT/irq/$_irq/effective_affinity_list"
	if ! echo "$_cpu" > "$_l" 2>/dev/null; then
		log "irq $_irq: failed to write cpu $_cpu"
		return 1
	fi
	_got=$(expand_list "$(cat "$_l" 2>/dev/null)")
	[ "$_got" = "$_cpu" ] || { log "irq $_irq: wanted cpu $_cpu, got ${_got:-unknown}"; return 1; }
	log "irq $_irq -> cpu $_cpu"
}

# One line per IRQ: "<irq> <cpu> <source>".
build_plan() {
	_ecpu=$(pick_eth_cpu)
	for _i in $(eth_irqs); do
		echo "$_i $_ecpu eth"
	done
	set -- $(pick_wifi_cpus)
	# fall back to the ethernet CPU so no discovered line goes unpinned
	[ $# -gt 0 ] || set -- $(pick_eth_cpu)
	_n=0
	while read -r _irq _name; do
		[ -n "${_irq:-}" ] || continue
		_j=0
		for _c in "$@"; do
			[ "$_j" -eq $((_n % $#)) ] && { _cpu="$_c"; break; }
			_j=$((_j + 1))
		done
		echo "$_irq $_cpu wifi:${_name}"
		_n=$((_n + 1))
	done <<WIFI
$(wifi_irqs)
WIFI
}

cmd_run() {
	case "$SMARTWRT_MODE" in
	manual|mixed) : ;;
	*) return 0 ;;
	esac
	[ -r "$PROC_ROOT/interrupts" ] || { log "/proc/interrupts unreadable"; return 1; }

	# PCIe enumerates late during boot; wait for the radios to show up.
	_t=0
	while :; do
		[ "$(eth_irqs | wc -l)" -gt 0 ] && [ "$(wifi_irqs | wc -l)" -gt 0 ] && break
		[ "$_t" -ge "$SMARTWRT_TIMEOUT" ] && { log "timeout waiting for IRQs after ${SMARTWRT_TIMEOUT}s"; break; }
		sleep 1; _t=$((_t + 1))
	done

	# Discover once: logging and applying must agree on the same plan.
	_plan=$(build_plan)
	log "plan: $(echo "$_plan" | tr '\n' ' ')"

	_rc=0
	while read -r _irq _cpu _what; do
		[ -n "${_irq:-}" ] || continue
		assign_one "$_irq" "$_cpu" || _rc=1
	done <<PLAN
$_plan
PLAN

	# write pinned IRQs for the init script to ban from irqbalance
	if [ "$SMARTWRT_MODE" = mixed ]; then
		mkdir -p "${PINNED%/*}" 2>/dev/null
		echo "$_plan" | awk '$3 == "eth" || $3 ~ /^wifi:/ { print $1 }' > "$PINNED"
		/etc/init.d/smartwrt-irq rebalance >/dev/null 2>&1 &
	fi
	return $_rc
}

cmd_status() {
	echo "cpus online : $CPUS_ONLINE"
	echo "$CACHE_GROUPS" | while read -r _l; do echo "cache groups : $_l"; done
	echo
	printf '%-6s %-6s %-10s %s\n' IRQ WANTED EFFECTIVE SOURCE
	build_plan | while read -r _irq _cpu _what; do
		printf '%-6s %-6s %-10s %s\n' "$_irq" "$_cpu" "$(cat "$PROC_ROOT/irq/$_irq/effective_affinity_list" 2>/dev/null)" "$_what"
	done
}

load_policy || exit 1
CPUS_ONLINE=$(online_cpus)
CACHE_GROUPS=$(compute_cache_groups)

case ${1:-run} in
	run)     cmd_run ;;
	status)  cmd_status ;;
	dry-run) build_plan ;;
	*)       echo "usage: $0 [run|status|dry-run]" >&2; exit 2 ;;
esac
