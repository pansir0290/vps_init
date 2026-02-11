#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
PLAIN='\033[0m'

[[ $EUID -ne 0 ]] && echo -e "${RED}错误：请以 root 用户运行此脚本！${PLAIN}" && exit 1

echo -e "${GREEN}=== VPS 系统初始化脚本 (严格防护版) ===${PLAIN}"

# 1. 开启 BBR
echo -e "${YELLOW}[1/6] 正在开启 BBR 加速...${PLAIN}"
if ! grep -q "net.core.default_qdisc=fq" /etc/sysctl.conf; then
    echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
    sysctl -p > /dev/null 2>&1
    echo -e "${GREEN}BBR 开启成功！${PLAIN}"
else
    echo -e "${GREEN}BBR 已经开启，跳过。${PLAIN}"
fi

# 2 & 3. 更新系统并安装基础依赖
echo -e "${YELLOW}[2-3/6] 正在更新系统并安装必要依赖...${PLAIN}"
apt update -y && apt upgrade -y && apt autoremove -y
apt install -y sudo curl wget unzip nano vim fail2ban

# 4. 修改 SSH 端口（交互式）
echo -e "${YELLOW}[4/6] 修改 SSH 端口${PLAIN}"
current_ssh_port=$(grep "^Port" /etc/ssh/sshd_config | awk '{print $2}')
[ -z "$current_ssh_port" ] && current_ssh_port=22

read -p "请输入新的 SSH 端口号 (当前: $current_ssh_port, 直接回车则不修改): " new_port
if [ -n "$new_port" ] && [ "$new_port" != "$current_ssh_port" ]; then
    sed -i "s/^#Port .*/Port $new_port/" /etc/ssh/sshd_config
    sed -i "s/^Port .*/Port $new_port/" /etc/ssh/sshd_config
    if ! grep -q "^Port" /etc/ssh/sshd_config; then
        echo "Port $new_port" >> /etc/ssh/sshd_config
    fi
    ssh_port=$new_port
    echo -e "${GREEN}SSH 端口已计划修改为: $ssh_port${PLAIN}"
else
    ssh_port=$current_ssh_port
    echo -e "${GREEN}保持原端口: $ssh_port${PLAIN}"
fi

# 5. 安装并配置 Fail2ban (10分钟内失败3次封禁24小时)
echo -e "${YELLOW}[5/6] 正在配置 Fail2ban...${PLAIN}"
cat <<EOF > /etc/fail2ban/jail.local
[sshd]
enabled = true
port    = $ssh_port
filter  = sshd
logpath = /var/log/auth.log
findtime = 10m
maxretry = 3
bantime = 24h
EOF

systemctl restart fail2ban
systemctl enable fail2ban > /dev/null 2>&1
echo -e "${GREEN}Fail2ban 配置完成：10分钟内失败3次，封禁24小时。已对齐端口 $ssh_port${PLAIN}"

# 6. 调整系统时区
echo -e "${YELLOW}[6/6] 调整系统时区${PLAIN}"
echo "-----------------------------------"
echo "1) 上海 (Asia/Shanghai)"
echo "2) 香港 (Asia/Hong_Kong)"
echo "3) 新加坡 (Asia/Singapore)"
echo "4) 韩国首尔 (Asia/Seoul)"
echo "5) 日本东京 (Asia/Tokyo)"
echo "6) 美国西海岸 (洛杉矶/圣何塞 - America/Los_Angeles)"
echo "7) 美国东海岸 (纽约 - America/New_York)"
echo "8) 英国伦敦 (Europe/London)"
echo "9) 保持当前/手动输入"
echo "-----------------------------------"
read -p "请输入 [1-9]: " tz_choice

case $tz_choice in
    1) timedatectl set-timezone Asia/Shanghai ;;
    2) timedatectl set-timezone Asia/Hong_Kong ;;
    3) timedatectl set-timezone Asia/Singapore ;;
    4) timedatectl set-timezone Asia/Seoul ;;
    5) timedatectl set-timezone Asia/Tokyo ;;
    6) timedatectl set-timezone America/Los_Angeles ;;
    7) timedatectl set-timezone America/New_York ;;
    8) timedatectl set-timezone Europe/London ;;
    *) read -p "请输入具体时区名称 (如 UTC): " manual_tz
       [ -n "$manual_tz" ] && timedatectl set-timezone $manual_tz ;;
esac
echo -e "${GREEN}时区设置为: $(timedatectl | grep "Time zone" | awk '{print $3}')${PLAIN}"

# 结束提示
echo -e "${GREEN}======================================${PLAIN}"
echo -e "${YELLOW}所有任务执行完毕！${PLAIN}"
echo -e "${RED}请务必牢记新端口号: [ $ssh_port ]${PLAIN}"
echo -e "${YELLOW}脚本即将询问是否重启...${PLAIN}"
echo -e "${GREEN}======================================${PLAIN}"

read -p "是否现在重启系统? (y/n): " confirm_reboot
if [[ "$confirm_reboot" == "y" || "$confirm_reboot" == "Y" ]]; then
    reboot
fi