#!/bin/bash
set -eu

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
SCRIPT_DIR="$ROOT_DIR"

for file in toolbox.sh install.sh lib/*.sh modules/*.sh scripts/*.sh tests/*.sh update_log.sh; do
    [ "$file" = "scripts/check_x86-64_psabi.sh" ] && continue
    bash -n "$file"
done

source lib/common.sh
source lib/i18n.sh
source lib/stats.sh

help_output=$(bash toolbox.sh --help)
[[ "$help_output" == *"系统信息"* && "$help_output" == *"toolbox.sh info"* ]] || {
    echo "CLI help output is incomplete." >&2
    exit 1
}
bash toolbox.sh info >/dev/null 2>&1 || {
    echo "Read-only system information command failed." >&2
    exit 1
}

language_test_root=$(mktemp -d)
previous_script_dir="$SCRIPT_DIR"
previous_home="$HOME"
previous_language="$CURRENT_LANG"
SCRIPT_DIR="$ROOT_DIR"
HOME="$language_test_root"
set_language invalid-language && {
    echo "Unknown language was accepted." >&2
    exit 1
}
[ "$CURRENT_LANG" = "cn" ] && [ "$(t menu_system_info)" = "系统信息查询" ] || {
    echo "Unknown language did not fall back to Chinese." >&2
    exit 1
}
save_language en && [ "$(t menu_system_info)" = "System information" ] || {
    echo "English language selection was not saved or applied." >&2
    exit 1
}
CURRENT_LANG=cn
load_language
[ "$CURRENT_LANG" = "en" ] || {
    echo "Saved language preference was not restored." >&2
    exit 1
}
SSH_TOOLBOX_LANG=unknown
load_language
[ "$CURRENT_LANG" = "cn" ] || {
    echo "Invalid language override did not fall back to Chinese." >&2
    exit 1
}
unset SSH_TOOLBOX_LANG
HOME="$previous_home"
SCRIPT_DIR="$previous_script_dir"
CURRENT_LANG="$previous_language"

[ "$(t menu_system_info)" = "System information" ] || {
    echo "English translation lookup failed." >&2
    exit 1
}
CURRENT_LANG=cn
[ "$(t menu_system_info)" = "系统信息查询" ] || {
    echo "Chinese translation lookup failed." >&2
    exit 1
}
[ "$(t 'menu_system_info; touch /tmp/should-not-exist' fallback)" = "fallback" ] || {
    echo "Invalid translation key was not safely rejected." >&2
    exit 1
}

while read -r module function_name; do
    [ -n "$module" ] || continue
    module_file="modules/${module}.sh"
    if [ ! -f "$module_file" ]; then
        echo "Missing menu module: $module_file" >&2
        exit 1
    fi
    source "$module_file"
    if [ "$(type -t "$function_name" 2>/dev/null || true)" != "function" ]; then
        echo "Missing menu function: ${module}.${function_name}" >&2
        exit 1
    fi
done <<'MODULES'
system_info system_info
system_manage system_update
system_manage system_clean
component_manage component_manage_menu
bbr bbr_menu
docker_manager docker_menu
warp_manager warp_menu
ldnmp ldnmp_menu
panel_tools panel_tools_menu
system_tools system_tools_menu
node_setup node_setup_menu
nat_vm nat_vm_menu
oracle_cloud oracle_cloud_menu
env_manage env_manage_menu
test_scripts test_scripts_menu
cluster cluster_menu
ai_tools ai_tools_menu
network_optimize network_optimize_menu
kpanel kpanel_menu
games_server games_server_menu
ssl_cert ssl_cert_menu
website_security website_security_menu
backup_migrate backup_migrate_menu
app_market app_market_menu
firewall firewall_menu
MODULES

cluster_test_root=$(mktemp -d)
trap 'rm -rf -- "${shortcut_test_root:-}" "${installer_test_root:-}" "${cluster_test_root:-}" "${language_test_root:-}" "${market_secure_test_root:-}" "${kpanel_preflight_root:-}"' EXIT
cluster_home="${cluster_test_root}/home"
mkdir -p "${cluster_home}/.ssh"
cat > "${cluster_home}/.ssh/config" <<'SSH_CONFIG'
Host prod-web staging-db *.example.com ?
  User deploy
Host backup-1 backup-2
  User backup
SSH_CONFIG
cluster_list=$(HOME="$cluster_home" cluster_list_aliases)
[ "$cluster_list" = $'prod-web\nstaging-db\nbackup-1\nbackup-2' ] || {
    echo "SSH alias listing did not filter wildcard entries or preserve unique aliases." >&2
    exit 1
}
cluster_ssh_status=0
ssh() {
    printf '[%s]' "$@" >> "${cluster_test_root}/ssh.log"
    printf '\n' >> "${cluster_test_root}/ssh.log"
    return "$cluster_ssh_status"
}
if HOME="$cluster_home" cluster_probe_alias 'unknown-host' >/dev/null 2>&1; then
    echo "Unknown SSH alias was accepted." >&2
    exit 1
fi
[ ! -f "${cluster_test_root}/ssh.log" ] || {
    echo "Unknown SSH alias invoked ssh." >&2
    exit 1
}
HOME="$cluster_home" cluster_probe_alias prod-web >/dev/null || {
    echo "Mock SSH handshake unexpectedly failed." >&2
    exit 1
}
cluster_probe_line=$(sed -n '1p' "${cluster_test_root}/ssh.log")
cluster_close_line=$(sed -n '2p' "${cluster_test_root}/ssh.log")
[[ "$cluster_probe_line" == "[-M][-S][${TMPDIR:-/tmp}/ssh-toolbox-probe."*"/control][-fN][-o][BatchMode=yes][-o][ConnectTimeout=5][-o][StrictHostKeyChecking=yes][prod-web]" &&
    "$cluster_close_line" == "[-S][${TMPDIR:-/tmp}/ssh-toolbox-probe."*"/control][-O][exit][prod-web]" ]] || {
    echo "SSH handshake used unexpected options or a remote command." >&2
    exit 1
}
: > "${cluster_test_root}/ssh.log"
cluster_ssh_status=255
if HOME="$cluster_home" cluster_connect_after_probe prod-web <<<"y" >/dev/null 2>&1; then
    echo "Failed SSH handshake unexpectedly proceeded to a session." >&2
    exit 1
fi
[ "$(wc -l < "${cluster_test_root}/ssh.log")" -eq 1 ] || {
    echo "Failed SSH handshake started an interactive SSH session." >&2
    exit 1
}
: > "${cluster_test_root}/ssh.log"
cluster_ssh_status=0
HOME="$cluster_home" cluster_connect_after_probe prod-web <<<"y" >/dev/null 2>&1 || {
    echo "Confirmed SSH connection failed with successful mock handshake." >&2
    exit 1
}
cluster_probe_line=$(sed -n '1p' "${cluster_test_root}/ssh.log")
cluster_close_line=$(sed -n '2p' "${cluster_test_root}/ssh.log")
cluster_connect_line=$(sed -n '3p' "${cluster_test_root}/ssh.log")
[ "$(wc -l < "${cluster_test_root}/ssh.log")" -eq 3 ] &&
    [[ "$cluster_probe_line" == "[-M][-S][${TMPDIR:-/tmp}/ssh-toolbox-probe."*"/control][-fN][-o][BatchMode=yes][-o][ConnectTimeout=5][-o][StrictHostKeyChecking=yes][prod-web]" &&
        "$cluster_close_line" == "[-S][${TMPDIR:-/tmp}/ssh-toolbox-probe."*"/control][-O][exit][prod-web]" &&
        "$cluster_connect_line" = "[prod-web]" ]] || {
    echo "Successful handshake did not lead to cleanup and a separate command-free interactive SSH call." >&2
    exit 1
}
unset -f ssh

clear() { :; }
break_end() { :; }
ssl_renewal_output=$(ssl_cert_menu <<< $'5\n0' 2>&1) && {
    echo "KPanel upstream renewal must remain blocked." >&2
    exit 1
}
[[ "$ssl_renewal_output" == *"暂未接入"* && "$ssl_renewal_output" == *"请勿直接运行 scripts/auto_cert_renewal.sh"* ]] || {
    echo "KPanel renewal warning is missing or incomplete." >&2
    exit 1
}

clear() { :; }
break_end() { :; }
if declare -F main_menu >/dev/null; then
    echo "Recursive main_menu helper should not be present." >&2
    exit 1
fi
for menu in component_manage_menu env_manage_menu nat_vm_menu node_setup_menu oracle_cloud_menu test_scripts_menu; do
    if ! "$menu" <<<"0" >/dev/null 2>&1; then
        echo "Menu did not return cleanly on choice 0: $menu" >&2
        exit 1
    fi
done

nat_invalid_choice_output=$(nat_vm_menu <<< $'11\n0' 2>&1)
[[ "$nat_invalid_choice_output" == *"请输入0~10的数字"* ]] || {
    echo "NAT menu accepted an out-of-range selection." >&2
    exit 1
}

stale_function_called=0
stale_function() { stale_function_called=1; }
if run_module missing_module stale_function >/dev/null 2>&1; then
    echo "Missing module unexpectedly loaded." >&2
    exit 1
fi
[ "$stale_function_called" -eq 0 ] || {
    echo "A stale function ran after module loading failed." >&2
    exit 1
}
if run_module system_info missing_entry >/dev/null 2>&1; then
    echo "Module without the requested entry unexpectedly ran." >&2
    exit 1
fi

dnf() {
    MOCK_DNF_ARGS=("$@")
    return "${MOCK_DNF_STATUS:-0}"
}
install toolbox-test-package >/dev/null || {
    echo "Package installation unexpectedly failed." >&2
    exit 1
}
[ "${MOCK_DNF_ARGS[*]}" = "install -y toolbox-test-package" ] || {
    echo "Package installation ran unexpected update/install operations." >&2
    exit 1
}
MOCK_DNF_STATUS=1
if install toolbox-test-package >/dev/null 2>&1; then
    echo "Package installation failure was not propagated." >&2
    exit 1
fi
unset -f dnf
unset MOCK_DNF_ARGS MOCK_DNF_STATUS

ENABLE_STATS=false
curl() {
    CURL_WAS_CALLED=1
}
sum_run_times
[ "${STATS_TODAY}" = "0" ] && [ "${STATS_TOTAL}" = "0" ] && [ "${CURL_WAS_CALLED:-0}" = "0" ] || {
    echo "Disabled run-count statistics unexpectedly made a request." >&2
    exit 1
}
unset -f curl

shortcut_test_root=$(mktemp -d)
trap 'rm -rf -- "${shortcut_test_root:-}" "${installer_test_root:-}" "${cluster_test_root:-}" "${language_test_root:-}"' EXIT
shortcut_entrypoint="${shortcut_test_root}/toolbox.sh"
shortcut_path="${shortcut_test_root}/bin/toolbox.sh"
mkdir -p "${shortcut_test_root}/bin"
printf '#!/bin/bash\n' > "$shortcut_entrypoint"
printf 'keep existing command\n' > "${shortcut_test_root}/bin/k"
create_shortcut_at "$shortcut_path" "$shortcut_entrypoint" k K free-alias >/dev/null 2>&1 || {
    echo "Shortcut setup failed." >&2
    exit 1
}
[ "$(cat "${shortcut_test_root}/bin/k")" = "keep existing command" ] || {
    echo "Shortcut setup overwrote an existing command." >&2
    exit 1
}
[ -e "${shortcut_test_root}/bin/free-alias" ] || {
    echo "Shortcut setup did not create the free alias." >&2
    exit 1
}
grep -q '^# SSH_TOOLBOX_MANAGED_WRAPPER$' "$shortcut_path" || {
    echo "Generated shortcut is missing its ownership marker." >&2
    exit 1
}

printf '%s\n' \
    '#!/bin/bash' \
    '# 在线获取最新脚本并执行' \
    'SCRIPT_URL="https://raw.githubusercontent.com/eooce/ssh_tool/main/ssh_tool.sh"' \
    > "$shortcut_path"
create_shortcut_at "$shortcut_path" "$shortcut_entrypoint" k K free-alias >/dev/null 2>&1 || {
    echo "Legacy shortcut migration failed." >&2
    exit 1
}
grep -q '^# SSH_TOOLBOX_MANAGED_WRAPPER$' "$shortcut_path" || {
    echo "Legacy upstream launcher was not replaced." >&2
    exit 1
}

managed_python_prefix="${shortcut_test_root}/managed-python"
managed_python_bin="${shortcut_test_root}/local-bin"
mkdir -p "$managed_python_prefix/bin" "$managed_python_bin"
printf 'managed\n' > "${managed_python_prefix}/bin/python3"
touch "${managed_python_prefix}/.ssh-toolbox-managed"
ln -s "${managed_python_prefix}/bin/python3" "${managed_python_bin}/python3"
printf 'system python\n' > "${managed_python_bin}/pip3"
remove_managed_python_install "$managed_python_prefix" "$managed_python_bin"
[ ! -e "$managed_python_prefix" ] &&
    { [ ! -L "${managed_python_bin}/python3" ] ||
        [ "$(cat "${managed_python_bin}/python3")" = "managed" ]; } &&
    [ "$(cat "${managed_python_bin}/pip3")" = "system python" ] || {
    echo "Managed Python cleanup removed unrelated files or kept its installation." >&2
    exit 1
}
unmanaged_python_prefix="${shortcut_test_root}/unmanaged-python"
mkdir -p "$unmanaged_python_prefix"
printf 'user install\n' > "${unmanaged_python_prefix}/user-data"
remove_managed_python_install "$unmanaged_python_prefix" "$managed_python_bin" >/dev/null 2>&1
[ "$(cat "${unmanaged_python_prefix}/user-data")" = "user install" ] || {
    echo "Python cleanup removed an unmarked installation." >&2
    exit 1
}

nat_test_root="${shortcut_test_root}/nat"
mkdir -p "$nat_test_root"
printf 'keep\n' > "${nat_test_root}/vm-user-data"
qm() {
    case "$1" in
        list) printf 'VMID NAME\n101 test-vm\n' ;;
        status) printf 'status: stopped\n' ;;
        stop|destroy) printf '%s %s\n' "$1" "$2" >> "${nat_test_root}/qm.log" ;;
    esac
}
iptables() { : > "${nat_test_root}/iptables.called"; }
(cd "$nat_test_root" && nat_vm_menu <<< $'3\nDELETE\n0' >/dev/null 2>&1)
[ "$(cat "${nat_test_root}/vm-user-data")" = "keep" ] &&
    grep -q '^destroy 101$' "${nat_test_root}/qm.log" &&
    [ ! -e "${nat_test_root}/iptables.called" ] || {
    echo "KVM deletion changed unrelated files or host firewall rules." >&2
    exit 1
}
unset -f qm iptables

lxc_test_root="${shortcut_test_root}/lxc"
mkdir -p "$lxc_test_root"
lxc() {
    printf '%s\n' "$*" >> "${lxc_test_root}/lxc.log"
}
(cd "$lxc_test_root" && nat_vm_menu <<< $'6\n4\ntest-container\nn\n0' >/dev/null 2>&1)
[ ! -e "${lxc_test_root}/lxc.log" ] || {
    echo "LXC deletion proceeded without confirmation." >&2
    exit 1
}
(cd "$lxc_test_root" && nat_vm_menu <<< $'6\n4\ntest-container\ny\n0' >/dev/null 2>&1)
grep -q '^delete test-container --force$' "${lxc_test_root}/lxc.log" || {
    echo "Confirmed LXC deletion did not target the requested container." >&2
    exit 1
}
unset -f lxc

incus_test_root="${shortcut_test_root}/incus"
mkdir -p "$incus_test_root"
incus() {
    printf '%s\n' "$*" >> "${incus_test_root}/incus.log"
}
(cd "$incus_test_root" && nat_vm_menu <<< $'10\n4\ntest-container\ny\n0' >/dev/null 2>&1)
grep -q '^delete test-container --force$' "${incus_test_root}/incus.log" || {
    echo "Confirmed Incus deletion did not target the requested container." >&2
    exit 1
}
unset -f incus

docker() {
    case "$1 $2" in
        "ps -aq") printf 'container-one\ncontainer-two\n' ;;
        "rm -f") printf '%s\n' "$@" > "${nat_test_root}/docker.log" ;;
    esac
}
(cd "$nat_test_root" && nat_vm_menu <<< $'8\ny\n0' >/dev/null 2>&1)
[ ! -e "${nat_test_root}/docker.log" ] || {
    echo "Docker deletion proceeded without the explicit DELETE confirmation." >&2
    exit 1
}
(cd "$nat_test_root" && nat_vm_menu <<< $'8\nDELETE\n0' >/dev/null 2>&1)
grep -q '^container-two$' "${nat_test_root}/docker.log" || {
    echo "Confirmed Docker deletion did not target the listed containers." >&2
    exit 1
}
unset -f docker

warp_test_root="${shortcut_test_root}/warp"
mkdir -p "$warp_test_root"
printf '#!/bin/bash\nprintf "executed\\n" > "$WARP_TEST_MARKER"\n' > "${warp_test_root}/remote.sh"
curl() {
    local destination=""
    while [ "$#" -gt 0 ]; do
        if [ "$1" = "-o" ] && [ "$#" -gt 1 ]; then
            destination="$2"
            shift 2
        else
            shift
        fi
    done
    cp "${warp_test_root}/remote.sh" "$destination"
    printf '%s\n' "$destination" > "${warp_test_root}/temp-path"
}
WARP_TEST_MARKER="${warp_test_root}/ran"
export WARP_TEST_MARKER
warp_menu <<<"n" >/dev/null 2>&1
[ ! -e "$WARP_TEST_MARKER" ] &&
    [ ! -e "$(cat "${warp_test_root}/temp-path")" ] || {
    echo "WARP manager ignored cancellation or failed temporary-file cleanup." >&2
    exit 1
}
warp_menu <<<"y" >/dev/null 2>&1
[ "$(cat "$WARP_TEST_MARKER")" = "executed" ] &&
    [ ! -e "$(cat "${warp_test_root}/temp-path")" ] || {
    echo "WARP manager failed to run the confirmed script or clean up." >&2
    exit 1
}
unset WARP_TEST_MARKER
unset -f curl

market_secure_test_root="${shortcut_test_root}/remote-market"
mkdir -p "${market_secure_test_root}/apps"
printf '#!/bin/bash\necho remote-fixture\n' > "${market_secure_test_root}/payload.sh"
cp tests/fixtures/remote-app-index.tsv "${market_secure_test_root}/index.tsv"
printf '#!/bin/bash\necho mismatch\n' > "${market_secure_test_root}/bad-payload.sh"
printf '#!/bin/bash\necho too-large\n' > "${market_secure_test_root}/large-payload.sh"
market_curl_calls=0
curl() {
    local output="" url="" previous="" write_out=0
    while [ "$#" -gt 0 ]; do
        case "$1" in
            --output) output="$2"; shift 2 ;;
            --write-out) write_out=1; shift 2 ;;
            --proto|--tlsv1.2|--max-filesize|--connect-timeout|--max-time) shift 2 ;;
            --fail|--silent|--show-error) shift ;;
            *) url="$1"; shift ;;
        esac
    done
    market_curl_calls=$((market_curl_calls + 1))
    case "$url" in
        https://catalog.example/index.tsv) cp "${market_secure_test_root}/index.tsv" "$output" ;;
        https://catalog.example/apps/demo.sh) cp "${market_secure_test_root}/payload.sh" "$output" ;;
        https://catalog.example/apps/mismatch.sh) cp "${market_secure_test_root}/bad-payload.sh" "$output" ;;
        https://catalog.example/apps/large.sh) head -c 1048577 /dev/zero > "$output" ;;
        https://catalog.example/apps/redirect.sh) printf 'redirect'; return 0 ;;
        *) return 22 ;;
    esac
    [ "$write_out" -eq 1 ] && printf '200'
}
previous_script_dir="$SCRIPT_DIR"
previous_home="$HOME"
SCRIPT_DIR="$market_secure_test_root"
HOME="${market_secure_test_root}/home"
mkdir -p "$HOME/.config/ssh-toolbox"
printf '%s\n' 'https://catalog.example/index.tsv' > "$HOME/.config/ssh-toolbox/app-index-url"
remote_index_output=$(app_market_list_remote)
[ "$remote_index_output" = $'demo\t1.2.3\tapps/demo.sh\t84ca131dc62d7a0fbc4f72de038d63b4eff1c4a94e6a1b243a530f545031f7c7\nmismatch\t1.0\tapps/mismatch.sh\t0000000000000000000000000000000000000000000000000000000000000000\nlarge\t1.0\tapps/large.sh\t0000000000000000000000000000000000000000000000000000000000000000\nredirect\t1.0\tapps/redirect.sh\t0000000000000000000000000000000000000000000000000000000000000000' ] || {
    printf 'Remote index output mismatch: <%s>\n' "$remote_index_output" >&2
    echo "Remote index parser did not accept only safe entries." >&2
    exit 1
}
app_market_download_output=$(app_market_download_remote <<<"1" 2>&1) || {
    printf 'Remote download output: <%s>\n' "$app_market_download_output" >&2
    echo "Valid remote app did not download." >&2
    exit 1
}
[ -f "$SCRIPT_DIR/apps/demo-1.2.3.sh" ] && [ "$(cat "$SCRIPT_DIR/apps/demo-1.2.3.sh")" = $'#!/bin/bash\necho remote-fixture' ] &&
    grep -Fxq 'url=https://catalog.example/apps/demo.sh' "$SCRIPT_DIR/apps/demo-1.2.3.sh.source" || {
    echo "Verified remote app was not safely saved under apps/." >&2
    exit 1
}
if app_market_download_remote <<<"1" >/dev/null 2>&1; then
    echo "Remote app download overwrote an existing file." >&2
    exit 1
fi
printf '%s\n' 'https://catalog.example/index.tsv' > "$HOME/.config/ssh-toolbox/app-index-url"
app_market_fetch() { cp "${market_secure_test_root}/bad-payload.sh" "$2"; }
if app_market_download_remote <<<"1" >/dev/null 2>&1; then
    echo "Remote app with a bad digest was accepted." >&2
    exit 1
fi
[ ! -e "$SCRIPT_DIR/apps/mismatch-1.0.sh" ] || { echo "Bad digest left a runnable artifact." >&2; exit 1; }
app_market_fetch() { head -c 1048577 /dev/zero > "$2"; }
if app_market_download_remote <<<"1" >/dev/null 2>&1; then
    echo "Oversized remote app was accepted." >&2
    exit 1
fi
app_market_fetch() { return 22; }
if app_market_download_remote <<<"1" >/dev/null 2>&1; then
    echo "Redirect/fetch failure was accepted." >&2
    exit 1
fi
if app_market_valid_https_url 'http://catalog.example/index.tsv' || app_market_valid_https_url 'https://user@catalog.example/index.tsv'; then
    echo "Non-HTTPS or credential-bearing index URL was accepted." >&2
    exit 1
fi
symlink_market_root="${market_secure_test_root}/symlink-root"
mkdir -p "$symlink_market_root/outside"
ln -s "$symlink_market_root/outside" "$symlink_market_root/apps-link"
SCRIPT_DIR="$symlink_market_root"
ln -s "$symlink_market_root/apps-link" "$SCRIPT_DIR/apps"
if app_market_download_remote <<<"1" >/dev/null 2>&1; then
    echo "Remote application download followed an apps/ symlink." >&2
    exit 1
fi
[ ! -e "$symlink_market_root/outside/demo-1.2.3.sh" ] || { echo "Remote app escaped apps/ through a symlink." >&2; exit 1; }
SCRIPT_DIR="$market_secure_test_root"
[ ! -e "$SCRIPT_DIR/apps/large-1.0.sh" ] || { echo "Failed download left a runnable artifact." >&2; exit 1; }
SCRIPT_DIR="$previous_script_dir"
HOME="$previous_home"
unset -f curl app_market_fetch

market_test_root="${shortcut_test_root}/market"
mkdir -p "${market_test_root}/apps" "${market_test_root}/scripts"
printf '#!/bin/bash\necho "market fixture executed"\n' > "${market_test_root}/apps/demo.sh"
previous_script_dir="$SCRIPT_DIR"
SCRIPT_DIR="$market_test_root"
market_output=$(app_market_menu <<< $'1\n1\ny')
SCRIPT_DIR="$previous_script_dir"
[[ "$market_output" == *"market fixture executed"* && "$market_output" == *"本地脚本：apps/demo.sh"* ]] || {
    echo "Local application market failed to launch a selected script." >&2
    exit 1
}

kpanel_preflight_root="${shortcut_test_root}/kpanel-preflight"
mkdir -p "$kpanel_preflight_root"
KPANEL_CURL_CALLS=0
curl() { KPANEL_CURL_CALLS=$((KPANEL_CURL_CALLS + 1)); return 1; }
docker() { printf '%s\n' "$*" >> "$kpanel_preflight_root/docker.log"; return 1; }
kpanel_preflight_output=$(kpanel_deploy_preflight <<< $'http://unsafe.example\n' 2>&1) && {
    echo "KPanel preflight accepted a non-HTTPS public URL." >&2
    exit 1
}
[[ "$kpanel_preflight_output" == *"必须输入 HTTPS origin"* ]] &&
    [ "$KPANEL_CURL_CALLS" -eq 0 ] && [ ! -e "$kpanel_preflight_root/docker.log" ] || {
    echo "Invalid KPanel URL caused downloads or Docker access." >&2
    exit 1
}
unset -f curl docker

kpanel_install_test_root="${shortcut_test_root}/kpanel-install"
mkdir -p "$kpanel_install_test_root"
KPANEL_EXPECTED_META=8b5fbac62fdc80023b23dea5c85c2e8f1b663047b429d03ac107543f41b3d43d
KPANEL_EXPECTED_AGENT=2447f669ca85c1d84ed228027db1f17793fb9b98b9ad0922bf602e85e4ec8543
curl() {
    local output="" url=""
    while [ "$#" -gt 0 ]; do
        case "$1" in
            -o) output="$2"; shift 2 ;;
            *) url="$1"; shift ;;
        esac
    done
    case "$url" in
        */kejilion-panel-meta-1.27.2.tar.gz) printf 'fixture-meta' > "$output" ;;
        */kejilion-agent-linux-amd64) printf 'fixture-agent' > "$output" ;;
        */SHA256SUMS) printf '%s  kejilion-agent-linux-amd64\n' "$KPANEL_EXPECTED_AGENT" > "$output" ;;
        *) return 1 ;;
    esac
}
sha256sum() {
    case "$1" in
        */kpanel-meta.tar.gz) printf '%s  %s\n' "$KPANEL_EXPECTED_META" "$1" ;;
        */kejilion-agent-linux-amd64) printf '%s  %s\n' "$KPANEL_EXPECTED_AGENT" "$1" ;;
        *) command sha256sum "$@" ;;
    esac
}
tar() {
    case "$1" in
        -tzf) printf 'kpanel/deploy/install.sh\nkpanel/deploy/preflight.sh\n' ;;
        --no-same-owner)
            local destination=""
            while [ "$#" -gt 0 ]; do
                if [ "$1" = "-C" ]; then destination="$2"; shift 2; else shift; fi
            done
            mkdir -p "$destination/kpanel/deploy"
            printf '#!/bin/sh\nexit 0\n' > "$destination/kpanel/deploy/install.sh"
            printf '#!/bin/sh\nexit 0\n' > "$destination/kpanel/deploy/preflight.sh"
            ;;
        *) return 1 ;;
    esac
}
KPANEL_PREFLIGHT_STATUS=1
KPANEL_INSTALL_LOG="${kpanel_install_test_root}/calls.log"
sh() {
    case "$1" in
        */preflight.sh)
            printf 'preflight\n' >> "$KPANEL_INSTALL_LOG"
            return "$KPANEL_PREFLIGHT_STATUS"
            ;;
        */install.sh)
            printf 'install' >> "$KPANEL_INSTALL_LOG"
            printf ' <%s>' "${@:2}" >> "$KPANEL_INSTALL_LOG"
            printf '\n' >> "$KPANEL_INSTALL_LOG"
            ;;
        *) echo "Unexpected sh command: $*" >&2; return 99 ;;
    esac
}
if kpanel_deploy_preflight <<< $'https://panel.example.com\n\nINSTALL\n' >/dev/null 2>&1; then
    echo "KPanel installation continued after official preflight failure." >&2
    exit 1
fi
[ "$(cat "$KPANEL_INSTALL_LOG")" = "preflight" ] || {
    echo "KPanel preflight failure called the installer." >&2
    exit 1
}
: > "$KPANEL_INSTALL_LOG"
KPANEL_PREFLIGHT_STATUS=0
kpanel_deploy_preflight <<< $'https://panel.example.com\n\nn\n' >/dev/null 2>&1 && {
    echo "KPanel deployment continued after first confirmation was declined." >&2
    exit 1
}
[ "$(cat "$KPANEL_INSTALL_LOG")" = "preflight" ] || {
    echo "Declined KPanel deployment ran the installer." >&2
    exit 1
}
: > "$KPANEL_INSTALL_LOG"
kpanel_deploy_preflight <<< $'https://panel.example.com\n\nINSTALL\nn\n' >/dev/null 2>&1 && {
    echo "KPanel deployment continued after second confirmation was declined." >&2
    exit 1
}
[ "$(grep -c '^install .*--dry-run' "$KPANEL_INSTALL_LOG")" -eq 1 ] &&
    [ "$(grep -c '^install ' "$KPANEL_INSTALL_LOG")" -eq 1 ] || {
    echo "KPanel second-confirmation refusal did not stop after dry-run." >&2
    exit 1
}
: > "$KPANEL_INSTALL_LOG"
kpanel_deploy_preflight <<< $'https://panel.example.com\n\nINSTALL\nINSTALL\n' >/dev/null 2>&1 || {
    echo "Confirmed KPanel install flow failed with mocked official assets." >&2
    exit 1
}
[ "$(grep -c '^install .*--dry-run' "$KPANEL_INSTALL_LOG")" -eq 1 ] &&
    [ "$(grep -c '^install ' "$KPANEL_INSTALL_LOG")" -eq 2 ] || {
    echo "Confirmed KPanel flow did not run exactly dry-run then install." >&2
    exit 1
}
unset -f curl sha256sum tar sh

kpanel_test_root="${shortcut_test_root}/kpanel"
mkdir -p "$kpanel_test_root"
docker() {
    case "$1 $2" in
        "ps -aq") printf 'kpanel-container\n' ;;
        "ps -a") printf 'CONTAINER ID NAMES STATUS\nkpanel-container kpanel Up\n' ;;
        "start kpanel-container"|"stop kpanel-container"|"restart kpanel-container"|"logs --tail"|"stats --no-stream")
            printf '%s\n' "$*" >> "${kpanel_test_root}/docker.log"
            ;;
    esac
}
kpanel_menu <<< $'2\nn\n0' >/dev/null 2>&1
[ ! -e "${kpanel_test_root}/docker.log" ] || {
    echo "KPanel container management ignored a cancelled confirmation." >&2
    exit 1
}
kpanel_menu <<< $'2\ny\n0' >/dev/null 2>&1
grep -q '^start kpanel-container$' "${kpanel_test_root}/docker.log" || {
    echo "KPanel manager failed to start the selected container." >&2
    exit 1
}
unset -f docker

rm -rf -- "$shortcut_test_root"

firewall_valid_port 1 && firewall_valid_port 65535 || {
    echo "Firewall port validation rejected a valid boundary." >&2
    exit 1
}
if firewall_valid_port 0 || firewall_valid_port 65536 || firewall_valid_port abc; then
    echo "Firewall port validation accepted an invalid port." >&2
    exit 1
fi

installer_test_root=$(mktemp -d)
trap 'rm -rf -- "${shortcut_test_root:-}" "${installer_test_root:-}" "${cluster_test_root:-}" "${language_test_root:-}"' EXIT
fixture_root="${installer_test_root}/fixture/ssh-toolbox-main"
mock_bin="${installer_test_root}/bin"
mkdir -p "$fixture_root/modules" "$mock_bin" "${installer_test_root}/home"
printf '#!/bin/bash\necho "fixture toolbox launched"\n' > "${fixture_root}/toolbox.sh"
cp install.sh "${fixture_root}/install.sh"
touch "${fixture_root}/modules/fixture.sh"
tar -czf "${installer_test_root}/fixture.tar.gz" -C "${installer_test_root}/fixture" ssh-toolbox-main
cat > "${mock_bin}/curl" <<'MOCK_CURL'
#!/bin/bash
while [ "$#" -gt 0 ]; do
    if [ "$1" = "-o" ] && [ "$#" -gt 1 ]; then
        cp "$SSH_TOOLBOX_TEST_ARCHIVE" "$2"
        exit
    fi
    shift
done
exit 1
MOCK_CURL
chmod +x "${mock_bin}/curl"

installer_output=$(
    HOME="${installer_test_root}/home" \
    PATH="${mock_bin}:${PATH}" \
    SUDO_USER= \
    SSH_TOOLBOX_TEST_ARCHIVE="${installer_test_root}/fixture.tar.gz" \
    bash install.sh
)
[[ "$installer_output" == *"fixture toolbox launched"* ]] || {
    echo "Installer failed to launch the installed toolbox." >&2
    exit 1
}
installed_dir="${installer_test_root}/home/.local/share/ssh-toolbox"
[ -f "${installed_dir}/.ssh-toolbox-managed" ] || {
    echo "Installer did not mark the managed installation." >&2
    exit 1
}

installer_output=$(
    HOME="${installer_test_root}/home" \
    PATH="${mock_bin}:${PATH}" \
    SUDO_USER= \
    SSH_TOOLBOX_TEST_ARCHIVE="${installer_test_root}/fixture.tar.gz" \
    bash install.sh
)
[[ "$installer_output" == *"Previous installation preserved at"* ]] || {
    echo "Installer failed to preserve the previous installation." >&2
    exit 1
}

installer_output=$(
    HOME="${installer_test_root}/home" \
    PATH="${mock_bin}:${PATH}" \
    SUDO_USER= \
    SSH_TOOLBOX_TEST_ARCHIVE="${installer_test_root}/fixture.tar.gz" \
    bash install.sh --update "$installed_dir"
)
[[ "$installer_output" == *"Previous installation preserved at"* &&
    "$installer_output" == *"fixture toolbox launched"* ]] || {
    echo "In-place updater failed to update and launch the managed installation." >&2
    exit 1
}

unmanaged_home="${installer_test_root}/unmanaged-home"
mkdir -p "${unmanaged_home}/.local/share/ssh-toolbox"
printf 'keep\n' > "${unmanaged_home}/.local/share/ssh-toolbox/user-data"
if HOME="$unmanaged_home" \
    PATH="${mock_bin}:${PATH}" \
    SUDO_USER= \
    SSH_TOOLBOX_TEST_ARCHIVE="${installer_test_root}/fixture.tar.gz" \
    bash install.sh >/dev/null 2>&1; then
    echo "Installer overwrote an unmanaged directory." >&2
    exit 1
fi
[ "$(cat "${unmanaged_home}/.local/share/ssh-toolbox/user-data")" = "keep" ] || {
    echo "Installer changed data in an unmanaged directory." >&2
    exit 1
}

unmanaged_update_dir="${installer_test_root}/unmanaged-update"
mkdir -p "$unmanaged_update_dir"
if SSH_TOOLBOX_TEST_ARCHIVE="${installer_test_root}/fixture.tar.gz" \
    bash install.sh --update "$unmanaged_update_dir" >/dev/null 2>&1; then
    echo "Updater accepted a directory not managed by SSH Toolbox." >&2
    exit 1
fi

trap - EXIT
rm -rf -- "$installer_test_root"

echo "Shell syntax and main-menu module smoke tests passed."
