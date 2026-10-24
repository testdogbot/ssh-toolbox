# SSH Toolbox

一个面向 Linux VPS 的 Bash 工具箱，整合常用系统管理功能及 `scripts/` 中的辅助脚本。项目当前采用按需 `source` 加载的模块结构。

## 运行要求

- Linux（Ubuntu、Debian、RHEL 系及 Alpine 等；各功能支持范围不同）
- Bash、curl、常见系统工具
- 系统管理功能通常需要 root 权限
- 修改系统或防火墙前请先备份，并确认云厂商控制台可用

## 使用

### 配置短域名（仅需一次）

仓库维护者需要在 Cloudflare 账号中为 `ssh-toolbox.alebot.ggff.net` 部署 Worker。仓库已提供 Worker 配置：

```bash
git clone https://github.com/testdogbot/ssh-toolbox.git
cd ssh-toolbox
npx wrangler login
npx wrangler deploy
```

部署环境需要 Node.js/npm；部署账户必须管理 `alebot.ggff.net` 所属 Cloudflare Zone，并允许为该子域名创建 Worker Custom Domain。Worker 会将 HTTP 请求重定向到 HTTPS，并仅在根路径返回最新版安装脚本。若 DNS/TLS 证书还在配置中，请等待 Cloudflare 激活 Custom Domain 后再使用。

### 在每台 VPS 上启动

短域名启用后，在每台 Linux VPS 上执行：

```bash
bash <(curl -Ls ssh-toolbox.alebot.ggff.net)
```

如果尚未配置短域名，也可以直接使用 GitHub Raw 地址：

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/testdogbot/ssh-toolbox/main/install.sh)
```

该入口会下载 `main` 分支并安装到 `/opt/ssh-toolbox`（使用 `sudo` 时）或 `~/.local/share/ssh-toolbox`，然后启动菜单。再次运行会更新由本安装器管理的目录，并保留上一版本备份。不要对已有但非本安装器管理的同名目录运行；安装器会拒绝覆盖。该方式依赖 VPS 能通过 HTTPS 访问 GitHub。

已安装的工具箱可以在主菜单选择 `00` 更新到 GitHub `main`，更新前会保留旧版本备份。自动更新计划任务尚未实现；从源码克隆运行的开发目录不会被原位更新，需重新运行安装入口。

如果项目已经克隆到服务器，也可直接启动：

```bash
bash toolbox.sh
```

运行 `bash toolbox.sh --help` 查看命令帮助；只读命令（如 `info`、`docker ps`、`sshkey`）不要求 root。菜单、软件包管理、系统更新/清理、SSL 申请和系统修改操作需要 root。

支持的命令行入口包括 `info`、`update`、`clean`、`bbr3`、`docker`、`ssl`、`app`、`kpanel`、`fail2ban` 和 `sshkey`。

## 模块

- `modules/`：菜单功能，主入口按选择加载
- `lib/`：公共函数、语言和统计功能
- `scripts/`：独立的安装/管理辅助脚本
- `config/`：服务配置模板
- `apps/`：本地应用脚本目录；应用市场还支持显式 HTTPS TSV 索引，校验 SHA-256 后将远程脚本下载到 `apps/`，不会自动执行

部分上游安装器会更改系统配置或从网络获取代码。运行前请阅读对应脚本；LDNMP 安装脚本会重置 iptables 默认策略。KPanel 菜单可管理已有容器（启动、停止、重启、日志和资源查看），并提供固定官方版本 v1.27.2 部署向导；向导会校验发布资产、执行官方只读预检和 dry-run，实际安装须两次明确确认，尚未在 Linux VPS 实机验证。SSL 菜单中的 KPanel 上游自动续期入口目前明确禁用：对应脚本可能删除 Certbot lineage、停止或重载 Nginx，且其失败处理未经验证；旧版脚本会清空主机防火墙规则。请勿直接运行这两份脚本。系统重装入口仅提供说明，不执行重装。

集群控制从 `~/.ssh/config` 读取非通配 `Host` 别名，并在交互连接前使用非交互 SSH ControlMaster 握手检查（BatchMode、5 秒连接超时）；只有握手成功并确认后才打开交互会话。探测不执行远程命令，且不支持仅依赖交互密码提示的目标。

语言设置可在主菜单选择 `77`，保存到 `~/.config/ssh-toolbox/language`；会话也可使用 `SSH_TOOLBOX_LANG=cn` 或 `SSH_TOOLBOX_LANG=en` 覆盖。当前重点菜单提供中英文，其他菜单仍按中文默认显示。

远程应用索引配置入口在应用市场菜单。索引为制表符分隔的四列：`name<TAB>version<TAB>relative_path<TAB>sha256`，路径必须是索引站点下的相对 `.sh` 文件。仅接受 HTTPS；下载不跟随重定向，单文件上限 1 MiB，校验摘要和 Bash 语法，拒绝路径穿越及覆盖。SHA-256 仅校验内容与索引一致，不证明来源可信；下载脚本只保存到 `apps/`，之后仍走本地来源展示与执行确认流程。

KPanel 菜单提供固定官方版本部署向导（当前锁定 v1.27.2）：先校验官方元数据包、架构对应 Agent 与镜像 digest，再运行发布包内的只读预检；用户输入 `INSTALL` 后先执行官方安装器 dry-run，再次输入 `INSTALL` 才进行实际安装。安装会新增 KPanel 专用文件、服务、容器与网络；不会修改 `kejilion.sh`、`/home/web`、现有 Nginx 配置或防火墙。需要公网 HTTPS origin、Linux、rootful Docker Compose v2 和 systemd/OpenRC；预检前可指定官方支持的私网 RFC1918 `/28` 以避开路由冲突。安装前请备份并审阅官方 v1.27.2 部署文档。该向导尚未在 Linux VPS 实机验证。

统计默认关闭（`ENABLE_STATS=false`），关闭时不会请求在线运行次数接口。系统语言环境不会被程序强行改写。快捷命令 `k` 和 `toolbox` 指向当前项目的 `toolbox.sh`，不会切换到其他上游脚本。

NAT 管理中的“删除所有 KVM/Docker”属于不可逆操作，必须输入 `DELETE` 才会继续；删除单个 LXC/Incus 容器也会二次确认。删除 KVM 不会清空宿主机防火墙规则、重启网络或删除当前目录文件；Docker 批量删除会影响宿主机上的全部容器。新建 Docker 小鸡使用随机 root 密码，凭据保存在 `/root/ssh-toolbox-vm-credentials.txt`，请妥善保管。环境管理仅卸载由对应系统包管理器管理的 Node.js/Java 包；Python 保留系统解释器，Go 只清理工具箱约定路径。

WARP 入口会先下载并做 Bash 语法检查，展示第三方脚本来源并要求确认后才运行；脚本下载到临时文件，完成或取消后都会清理。请只运行你信任的第三方脚本。

## 验证

```bash
bash tests/test_module_smoke.sh
node --test tests/test_short_link_worker.mjs
```

该检查验证所有 Shell 文件语法、菜单返回行为、快捷入口不覆盖既有文件、Python 清理边界，以及 KVM/Docker 批量删除的确认与副作用。

## 许可证

Apache License 2.0，详见 [LICENSE](./LICENSE)。部分辅助脚本来自其上游项目，使用前请核实各文件标注的来源和许可。
