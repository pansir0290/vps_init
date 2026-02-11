# VPS 一键初始化脚本

这是一个专为 VPS（特别是 DD 系统后）设计的系统初始化脚本，旨在快速完成基础优化、依赖安装、安全加固及环境配置。

## 🚀 功能特性

1.  **内核优化**：自动开启内核 BBR 加速。
2.  **系统更新**：执行 `apt update & upgrade` 并自动清理陈旧依赖。
3.  **必备工具**：安装 `curl`, `wget`, `unzip`, `nano`, `vim`, `sudo` 等。
4.  **安全加固 (SSH)**：交互式修改 SSH 默认端口，防扫描。
5.  **暴力破解防护**：安装并配置 `Fail2ban`。
    * **严格策略**：10 分钟内连续失败 **3 次**即封禁该 IP **24 小时**。
    * **自动同步**：防护端口自动对齐你修改后的新 SSH 端口。
6.  **时区设置**：提供多地区时区选择（上海、香港、新加坡、韩国、美西、东京等）。
7.  **重启提醒**：完成后打印新端口号并提示重启，确保配置生效。

## 📦 如何使用

在你的 VPS 终端（root 用户）复制并执行以下命令：


```bash
apt update -y && apt install -y curl && curl -L https://raw.githubusercontent.com/pansir0290/vps_init/main/init.sh -o init.sh && chmod +x init.sh && ./init.sh
