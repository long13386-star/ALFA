#!/bin/bash
# sb-opt 一键安装（小白版）
# 用法：把下面这一行，换成你自己的 GitHub raw 地址，然后把这个文件也传到 GitHub
# raw 地址长这样：https://raw.githubusercontent.com/你的用户名/你的仓库名/main/sb-opt.sh
RAW_URL="https://raw.githubusercontent.com/long13386-star/ALFA/main/sb-opt.sh"

curl -Ls -o /root/sb-opt.sh "$RAW_URL"
chmod +x /root/sb-opt.sh
bash /root/sb-opt.sh
