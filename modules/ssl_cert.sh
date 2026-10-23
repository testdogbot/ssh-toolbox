#!/bin/bash
# ============================================================
# 模块: ssl_cert (SSL 证书)
# ============================================================
ssl_ps() {
    if command -v certbot >/dev/null 2>&1; then
        certbot certificates
    else
        echo "未检测到 certbot。"
        return 1
    fi
}

add_ssl() {
    local domain email
    if ! command -v certbot >/dev/null 2>&1; then
        echo "请先安装 certbot 及对应 Web 服务器插件。"
        return 1
    fi
    read -r -p "域名（例如 example.com）: " domain
    [[ "$domain" =~ ^([A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?\.)+[A-Za-z]{2,}$ ]] || {
        echo "域名格式无效。"
        return 1
    }
    read -r -p "联系邮箱: " email
    [[ "$email" =~ ^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$ ]] || {
        echo "邮箱格式无效。"
        return 1
    }
    confirm_action "使用 standalone 模式申请 ${domain}（需要 80 端口可用）?" &&
        certbot certonly --standalone --non-interactive --agree-tos --email "$email" -d "$domain"
}

ssl_cert_menu() {
    local choice
    while true; do
        clear
        echo "▶ SSL 证书"
        echo "1. 申请证书（certbot standalone）"
        echo "2. 查看证书"
        echo "3. 测试自动续期"
        echo "4. 执行证书续期"
        echo "0. 返回主菜单"
        read -r -p "请选择: " choice
        case "$choice" in
            1) add_ssl ;;
            2) ssl_ps ;;
            3) certbot renew --dry-run ;;
            4) confirm_action "执行 certbot renew?" && certbot renew ;;
            0) return 0 ;;
            *) echo "无效的输入。" ;;
        esac
        [ "$choice" = "0" ] || break_end
    done
}
