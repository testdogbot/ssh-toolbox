#!/bin/bash
# ============================================================
# 模块: node_setup (节点搭建合集)
# 来源: ssh_tool.sh 主菜单选项12 (第5068-5456行)
# 依赖: lib/common.sh (install, break_end, main_menu, 颜色变量)
# 功能: 各种代理节点一键搭建 (sing-box, xray, hysteria2, reality 等)
# ============================================================
node_setup_menu() {
while true; do
    clear
    echo -e "${purple}▶ 节点搭建脚本合集${re}"
    echo -e "${green}---------------------------------------------------------${re}"
    echo -e "${green}       Sing-box多合一             Argo-tunnel${re}"
    echo -e "${green}---------------------------------------------------------${re}"
    echo -e "${white} 1. F佬Sing-box一键脚本        5. 老王xray-2go一键脚本${re}"
    echo -e "${white} 2. 老王Sing-box四合一         6. F佬ArgoX一键脚本${re}"
    echo -e "${white} 3. 勇哥Sing-box四合一         7. Suoha一键Argo脚本${re}"
    echo -e "${white} 4. 233boy.sing-box一键脚本    8. 老王小钢炮(可挂哪吒)${re}"
    echo -e "${yellow}---------------------------------------------------------${re}"
    echo -e "${yellow}        单协议                    XRAY面板及其他${re}"
    echo -e "${yellow}---------------------------------------------------------${re}"
    echo -e "${white} 9. 老王Hysteria2一键脚本     13.新版X-UI面板一键脚本${re}"
    echo -e "${white}10. 老王Juicity一键脚本       14.伊朗版3X-UI面板一键脚本${re}"
    echo -e "${white}11. 老王Tuic-v5一键脚本       15.OpenVPN一键安装脚本${re}"
    echo -e "${white}12. Snell一键安装脚本         16.一键搭建TG代理${re}"
    echo -e "${white}17. 老王Reality一键脚本       18.sing-box面板(sui) ▶${re}"
    echo "---------------------------------------------------------"
    echo -e "${skyblue} 0. 返回主菜单${re}"
    echo "---------------"
    read -p "$(echo -e ${red}请输入你的选择: ${re})" sub_choice

    case $sub_choice in
        1) clear; bash <(wget -qO- https://raw.githubusercontent.com/fscarmen/sing-box/main/sing-box.sh); break_end ;;
        2) clear; bash <(curl -Ls https://raw.githubusercontent.com/eooce/sing-box/main/sing-box.sh); break_end ;;
        3) clear; bash <(curl -Ls https://raw.githubusercontent.com/yonggekkk/sing-box-yg/main/sb.sh); break_end ;;
        4) clear; install wget; bash <(wget -qO- -o- https://github.com/233boy/sing-box/raw/main/install.sh); break_end ;;
        5) clear; bash <(curl -Ls https://github.com/eooce/xray-2go/raw/main/xray_2go.sh); break_end ;;
        6) clear; bash <(wget -qO- https://raw.githubusercontent.com/fscarmen/argox/main/argox.sh); break_end ;;
        7) clear; bash <(curl -Ls https://www.baipiao.eu.org/suoha.sh); break_end ;;
        8)
            clear; install wget bash; clear
            read -p "$(echo -e "${yellow}是否需要安装哪吒探针？(y/n) 【直接回车不安装】: ${re}")" nezha
            if [ "$nezha" == "y" ] || [ "$nezha" == "Y" ]; then
                read -p "$(echo -e "${purple}请输入哪吒客域名(v1格式: nezha.xxx.com:8008  v0格式: nezha.xxx.com): ${re}")" nzserver
                read -p "$(echo -e "${purple}请输入哪吒agent端口(哪吒v1请直接回车留空): ${re}")" nzport
                read -p "$(echo -e ${purple}请输入哪吒agnt密钥: ${re})" nzkey
            fi
            read -p "$(echo -e "${yellow}是否需要使用固定隧道？(直接回车将使用临时隧道 y/n) : ${re}")" isargo
            if [ "$isargo" == "y" ] || [ "$isargo" == "Y" ]; then
                read -p "$(echo -e "${purple}请输入固定隧道的域名(格式: xxx.xxx.com): ${re}")" argodomain
                read -p "$(echo -e "${purple}请输入固定隧道密钥(json或token): ${re}")" argokey
            fi
            read -p "$(echo -e "${yellow}是否需要直连协议(hy2,tuic,reality,anytls,socks5,anyReality等,直接回车不启用)？(y/n) : ${re}")" isdirect
            if [ "$isdirect" == "y" ] || [ "$isdirect" == "Y" ]; then
                read -p "$(echo -e "${purple}请输入Hy2节点端口(不需要可直接回车留空): ${re}")" hy2pt
                read -p "$(echo -e "${purple}请输入Tuic节点端口(不需要可直接回车留空): ${re}")" tuicpt
                read -p "$(echo -e "${purple}请输入Reality节点端口(不需要可直接回车留空): ${re}")" realitypt
                read -p "$(echo -e "${purple}请输入Anytls节点端口(不需要可直接回车留空): ${re}")" anytlspt
                read -p "$(echo -e "${purple}请输入Socks5节点端口(不需要可直接回车留空): ${re}")" socks5pt
                read -p "$(echo -e "${purple}请输入AnyReality节点端口(不需要可直接回车留空): ${re}")" anyrealitypt
            fi
            read -p "$(echo -e "${purple}请输入你的UUID(留空将随机生成,哪吒v1将依赖此uuid): ${re}")" uuid
            [[ -z $uuid ]] && uuid=$(cat /proc/sys/kernel/random/uuid)
            UUID=$uuid NEZHA_SERVER=$nzserver NEZHA_PORT=$nzport NEZHA_KEY=$nzkey ARGO_DOMAIN=$argodomain ARGO_AUTH=$argokey HY2_PORT=$hy2pt TUIC_PORT=$tuicpt REALITY_PORT=$realitypt ANYTLS_PORT=$anytlspt S5_PORT=$socks5pt ANYREALITY_PORT=$anyrealitypt bash <(curl -Ls https://main.ssss.nyc.mn/sb.sh)
            sleep 1; break_end
            ;;
        9)
            while true; do
                clear
                echo "--------------"
                echo -e "${green}1.安装Hysteria2${re}"
                echo -e "${red}2.卸载Hysteria2${re}"
                echo -e "${yellow}3.更换Hysteria2端口${re}"
                echo "--------------"
                echo -e "${skyblue}0. 返回上一级菜单${re}"
                echo "--------------"
                read -p "$(echo -e ${red}请输入你的选择: ${re})" sub_choice
                case $sub_choice in
                    1)
                        clear
                        read -p "$(echo -e "${purple}请输入Hysteria2节点端口(nat小鸡请输入可用端口范围内的端口),回车跳过则使用随机端口：${re}")" port
                        [[ -z $port ]]
                        until [[ -z $(netstat -tuln | grep -w udp | awk '{print $4}' | sed 's/.*://g' | grep -w "$port") ]]; do
                            if [[ -n $(netstat -tuln | grep -w udp | awk '{print $4}' | sed 's/.*://g' | grep -w "$port") ]]; then
                                echo -e "${red}${port}端口已经被其他程序占用，请更换端口重试${re}"
                                read -p "$(echo -e ${purple}设置Hysteria2端口[1-65535]（回车将使用随机端口）：${re})" port
                                [[ -z $HY2_PORT ]] && port=8880
                            fi
                        done
                        if [ -f "/etc/alpine-release" ]; then
                            SERVER_PORT=$port bash -c "$(curl -L https://raw.githubusercontent.com/eooce/scripts/master/containers-shell/hy2.sh)"
                        else
                            HY2_PORT=$port bash -c "$(curl -L https://raw.githubusercontent.com/eooce/scripts/master/Hysteria2.sh)"
                        fi
                        sleep 1; break_end
                        ;;
                    2)
                        if [ -f "/etc/alpine-release" ]; then
                            pkill -f '[w]eb'; pkill -f '[n]pm'
                            cd && rm -rf web npm server.crt server.key config.yaml
                        else
                            systemctl stop hysteria-server.service
                            rm /usr/local/bin/hysteria
                            rm /etc/systemd/system/hysteria-server.service
                            rm /etc/hysteria/config.yaml
                            sudo systemctl daemon-reload
                            clear
                        fi
                        echo -e "${green}Hysteria2已卸载${re}"; break_end
                        ;;
                    3)
                        clear
                        read -p "$(echo -e ${purple}设置Hysteria2端口[1-65535]（回车跳过将使用随机端口）：${re})" new_port
                        [[ -z $new_port ]] && new_port=$(shuf -i 2000-65000 -n 1)
                        until [[ -z $(netstat -tuln | grep -w udp | awk '{print $4}' | sed 's/.*://g' | grep -w "$new_port") ]]; do
                            if [[ -n $(netstat -tuln | grep -w udp | awk '{print $4}' | sed 's/.*://g' | grep -w "$new_port") ]]; then
                                echo -e "${red}${new_port}端口已经被其他程序占用，请更换端口重试${re}"
                                read -p "$(echo -e ${purple}设置Hysteria2端口[1-65535]（回车跳过将使用随机端口）：${re})" new_port
                                [[ -z $new_port ]] && new_port=$(shuf -i 2000-65000 -n 1)
                            fi
                        done
                        if [ -f "/etc/alpine-release" ]; then
                            sed -i "s/^listen: :[0-9]*/listen: :$new_port/" /root/config.yaml
                            pkill -f '[w]eb'; nohup ./web server config.yaml >/dev/null 2>&1 &
                        else
                            clear
                            sed -i "s/^listen: :[0-9]*/listen: :$new_port/" /etc/hysteria/config.yaml
                            systemctl restart hysteria-server.service
                        fi
                        echo -e "${green}Hysteria2端口已更换成$new_port,请手动更改客户端配置!${re}"
                        sleep 1; break_end
                        ;;
                    0) break ;;
                    *) echo -e "${red}无效的输入!${re}" ;;
                esac
            done
            ;;
        10) clear; bash <(curl -Ls https://raw.githubusercontent.com/eooce/scripts/master/juicity.sh); break_end ;;
        11) clear; bash -c "$(curl -L https://raw.githubusercontent.com/eooce/scripts/master/tuic.sh)"; break_end ;;
        12) clear; install wget && wget -O snell.sh --no-check-certificate https://git.io/Snell.sh && chmod +x snell.sh && ./snell.sh; break_end ;;
        13) clear; bash <(curl -Ls https://raw.githubusercontent.com/slobys/x-ui/main/install.sh); break_end ;;
        14) clear; bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh); break_end ;;
        15) clear; install wget && wget https://git.io/vpn -O openvpn-install.sh && bash openvpn-install.sh; break_end ;;
        16)
            clear; install iproute2; clear
            read -p "$(echo -e "${purple}请输入MTProto代理端口(直接回车则使用随机端口): ${re}")" port
            while true; do
                if [[ -z $port ]]; then
                    port=$(shuf -i 2000-65000 -n 1)
                    echo -e "${green}使用随机端口: $port${re}"
                fi
                if [[ -n $(ss -tln | grep ":$port ") ]] || [[ -n $(lsof -i :$port 2>/dev/null) ]]; then
                    if [[ $port == "$original_port" ]]; then
                        echo -e "${red}${port}端口已经被其他程序占用，请更换端口重试${re}"
                    else
                        echo -e "${red}随机生成的端口 ${port} 已被占用，重新生成...${re}"
                    fi
                    port=""; continue
                else
                    break
                fi
            done
            PORT=$port bash <(curl -Ls https://raw.githubusercontent.com/eooce/scripts/master/mtp.sh)
            sleep 1; break_end
            ;;
        17)
            while true; do
                clear
                echo "--------------"
                echo -e "${green}1.安装Reality${re}"
                echo -e "${red}2.卸载Reality${re}"
                echo -e "${yellow}3.更换Reality端口${re}"
                echo "--------------"
                echo -e "${skyblue}0. 返回上一级菜单${re}"
                echo "--------------"
                read -p "$(echo -e ${red}请输入你的选择: ${re})" sub_choice
                case $sub_choice in
                    1)
                        clear; install lsof; clear
                        read -p "$(echo -e "${purple}请输入reality节点端口(nat小鸡请输入可用端口范围内的端口),回车跳过则使用随机端口：${re}")" port
                        [[ -z $port ]]
                        until [[ -z $(lsof -i :$port 2>/dev/null) ]]; do
                            if [[ -n $(lsof -i :$port 2>/dev/null) ]]; then
                                echo -e "${red}${port}端口已经被其他程序占用，请更换端口重试${re}"
                                read -p "$(echo -e ${purple}设置 reality 端口[1-65535]（回车跳过将使用随机端口）：${re})" port
                                [[ -z $port ]] && port=$(shuf -i 2000-65000 -n 1)
                            fi
                        done
                        if [ -f "/etc/alpine-release" ]; then
                            PORT=$port bash -c "$(curl -L https://raw.githubusercontent.com/eooce/scripts/master/test.sh)"
                        else
                            PORT=$port bash -c "$(curl -L https://raw.githubusercontent.com/eooce/xray-reality/master/reality.sh)"
                        fi
                        sleep 1; break_end
                        ;;
                    2)
                        if [ -f "/etc/alpine-release" ]; then
                            pkill -f '[w]eb'; pkill -f '[n]pm'; cd && rm -rf app; clear
                        else
                            sudo systemctl stop xray
                            sudo rm /usr/local/bin/xray /etc/systemd/system/xray.service /usr/local/etc/xray/config.json /usr/local/share/xray/geoip.dat /usr/local/share/xray/geosite.dat /etc/systemd/system/xray@.service
                            sudo systemctl daemon-reload
                            sudo rm -rf /var/log/xray /var/lib/xray
                            clear
                        fi
                        echo -e "${green}Reality已卸载${re}"; break_end
                        ;;
                    3)
                        clear
                        read -p "$(echo -e ${purple}设置 reality 端口[1-65535]（回车跳过将使用随机端口）：${re})" new_port
                        [[ -z $new_port ]] && new_port=$(shuf -i 2000-65000 -n 1)
                        until [[ -z $(lsof -i :$new_port 2>/dev/null) ]]; do
                            if [[ -n $(lsof -i :$new_port 2>/dev/null) ]]; then
                                echo -e "${red}${new_port}端口已经被其他程序占用，请更换端口重试${re}"
                                read -p "$(echo -e ${purple}设置reality端口[1-65535]（回车跳过将使用随机端口）：${re})" new_port
                                [[ -z $new_port ]] && new_port=$(shuf -i 2000-65000 -n 1)
                            fi
                        done
                        install jq
                        if [ -f "/etc/alpine-release" ]; then
                            jq --argjson new_port "$new_port" '.inbounds[0].port = $new_port' /root/app/config.json > tmp.json && mv tmp.json /root/app/config.json
                            pkill -f '[w]eb'; cd ~ && cd app; nohup ./web -c config.json >/dev/null 2>&1 &
                        else
                            clear
                            jq --argjson new_port "$new_port" '.inbounds[0].port = $new_port' /usr/local/etc/xray/config.json > tmp.json && mv tmp.json /usr/local/etc/xray/config.json
                            systemctl restart xray.service
                        fi
                        echo -e "${green}Reality端口已更换成$new_port,请手动更改客户端配置!${re}"
                        sleep 1; break_end
                        ;;
                    0) break ;;
                    *) echo -e "${red}无效的输入!${re}" ;;
                esac
            done
            ;;
        18)
            while true; do
                clear
                echo -e "${skyblue}▶ Sui面板${re}"
                echo "--------------"
                echo -e "${green}1.安装sui面板${re}"
                echo -e "${red}2.卸载sui面板${re}"
                echo "--------------"
                echo -e "${skyblue}0. 返回上一级菜单${re}"
                echo "--------------"
                read -p "$(echo -e ${red}请输入你的选择: ${re})" sub_choice
                case $sub_choice in
                    1) bash <(curl -Ls https://raw.githubusercontent.com/Misaka-blog/s-ui/master/install.sh); sleep 2; echo ""; break_end ;;
                    2)
                        systemctl disable sing-box --now
                        systemctl disable s-ui --now
                        rm -f /etc/systemd/system/s-ui.service /etc/systemd/system/sing-box.service
                        systemctl daemon-reload
                        rm -fr /usr/local/s-ui
                        clear; echo -e "${green}sui面板已卸载${re}"; break_end
                        ;;
                    0) break ;;
                    *) echo -e "${red}无效的输入!${re}" ;;
                esac
            done
            ;;
        0) return 0 ;;
        *) break ;;
    esac
done
}
