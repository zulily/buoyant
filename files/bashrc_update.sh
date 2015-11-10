#!/bin/bash
# Update the root user's .bashrc

echo "ps wuax |grep [s]ystemd >/dev/null || systemd & >/dev/null 2>&1" >> /root/.bashrc
echo "ps wuax |grep [s]alt-minion >/dev/null || salt-minion -d" >> /root/.bashrc

# Let's not run the systemd login manager
echo "systemctl stop systemd-logind.service 2>/dev/null" >> /root/.bashrc
echo "systemctl mask systemd-logind.service 2>/dev/null" >> /root/.bashrc
