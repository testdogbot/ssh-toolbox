#!/bin/bash
set -eu

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

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

firewall_valid_port 1 && firewall_valid_port 65535 || {
    echo "Firewall port validation rejected a valid boundary." >&2
    exit 1
}
if firewall_valid_port 0 || firewall_valid_port 65536 || firewall_valid_port abc; then
    echo "Firewall port validation accepted an invalid port." >&2
    exit 1
fi

installer_test_root=$(mktemp -d)
trap 'rm -rf -- "$installer_test_root"' EXIT
fixture_root="${installer_test_root}/fixture/ssh-toolbox-main"
mock_bin="${installer_test_root}/bin"
mkdir -p "$fixture_root/modules" "$mock_bin" "${installer_test_root}/home"
printf '#!/bin/bash\necho "fixture toolbox launched"\n' > "${fixture_root}/toolbox.sh"
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

trap - EXIT
rm -rf -- "$installer_test_root"

echo "Shell syntax and main-menu module smoke tests passed."
