# sb-opt.sh — 帶優化的 sing-box-yg 副本

上游：`yonggekkk/sing-box-yg` 的 `sb.sh`（2026-11-23 下載）
上游 SHA256：`30064ac7b9666753dc0dff3f9f310b622b127975ccd142be1f696530f28d9b14`
本檔案 SHA256：`6a0af9096a3ae3bca1840bd947b63a475f5452b2eacc2d34ccb70800a5018059`
版本：`SB_OPT_VERSION=1.0-20261123`

## 改了什麼（相對上游）

| 位置 | 上游 | sb-opt |
|---|---|---|
| sb10 / sb11 服務端 Hy2 | `ignore_client_bandwidth: false`，無上下行 | `up_mbps` / `down_mbps: ${HY_MBPS}`，`ignore_client_bandwidth: true` |
| sb10 / sb11 服務端 TUIC | 只有 `congestion_control: bbr` | 加 `zero_rtt_handshake: true`、`heartbeat: "10s"` |
| sb10 / sb11 日誌 | `level: "info"` | `level: "warn"`，加 `experimental.cache_file`（`enabled: true, store_dns: true`） |
| sbox.json 客戶端 TUIC | `zero_rtt_handshake: false` | `true`（heartbeat 本來已是 10s） |
| clmi.yaml Hy2 節點 | 無 `up` / `down` | 加 `up: "${HY_MBPS} Mbps"` / `down: "${HY_MBPS} Mbps"` |
| 內核調校 | 無（只有 menu 11 另叫 teddysun bbr.sh） | 安裝時寫入 `/etc/sysctl.d/99-singbox-speed.conf`：BBR+fq、16 MB 緩衝、`tcp_fastopen=3`、backlog 8192 |
| menu 11 | teddysun bbr.sh | 改為跑上面嗰份 sysctl 優化 |
| 82 號東京機例外 | 無 | 檢測到 `/etc/skyline-speeder/speeder.toml` 或 `skyline-speederd` 在跑時，擁塞控制保持 `skyline_cc`，唔強制 BBR |
| 備份 | 無 | 每次生成 sb10/sb11 前，備份現有 `sb.json/sb10.json/sb11.json/clmi.yaml/sbox.json` 到 `/root/sb-opt-backup-YYYYMMDD-HHMMSS/` |
| `lnsb()`（寫 `/usr/bin/sb`） | 從上游重新下載 sb.sh | 改為複製返呢份帶優化版，唔會從上游覆蓋 |
| menu 7（更新腳本） | 從上游更新 | 預設拒絕，並說明原因；除非 `SB_OPT_ALLOW_UPSTREAM_UPDATE=1` |
| `close()` 防火牆 | `iptables -F`（filter 表） | 加咗 `iptables-save -t nat` 備份到 `/etc/s-box/iptables-nat.bak`。更正：`-F` 預設只清 filter 表，NAT 表嘅 Hy2/TUIC 端口跳躍 DNAT 規則本身唔會被清走 |

## Hy2 頻寬點決定

優先順序：環境變數 `HY_MBPS` → 保留現有 `/etc/s-box/sb.json` 入面嘅 `up_mbps` → 安裝時提示輸入 → 預設 1000。

每台機嘅值：103 香港 100、107 美國 500、198 美國 975、法蘭克福 1000、東京 212 800、Evoxt 香港 800、RackNerd 600、東京 82 1000。

## 點用

**唔好再用 `bash <(wget …)` 嗰種管道方式跑呢份。** 因為 `lnsb()` 要複製返實體檔案去 `/usr/bin/sb`，管道方式無實體檔案可以複製。

```bash
# 1. 傳到伺服器（例如用 scp）
scp sb-opt.sh root@<伺服器IP>:~/sb-opt.sh

# 2. 登入伺服器，指定 Hy2 頻寬跑（以 107 美國為例）
HY_MBPS=500 bash ~/sb-opt.sh

# 或者唔指定，安裝時佢會問你，預設 1000
bash ~/sb-opt.sh
```

之後再跑 `sbshare`（menu 9）重新生成訂閱，佢會自動沿用返現有 `sb.json` 嘅 Hy2 頻寬，唔使再輸入。

## 驗證過嘅嘢（2026-11-23，喺本機做，唔係伺服器上）

- `bash -n sb-opt.sh` 通過
- patch 腳本 `patch_sb.py` 逐項 assert 替換次數：Hy2 2 處、TUIC 服務端 2 處、TUIC 客戶端 1 處、log warn 3 處、cache_file 3 處（2 服務端 + 1 客戶端）、clmi up/down 1 處；無殘留 `ignore_client_bandwidth: false`、`zero_rtt_handshake: false`、`level: "info"`、teddysun bbr.sh
- 用假變數實際跑咗 `inssbjsonser()` 同 `clall()` 渲染模板（`HY_MBPS=500`）：生成嘅 sb10/sb11/sb.json 經 JSON 解析，Hy2 係 500/500 + `ignore_client_bandwidth: true`，TUIC 係 0-RTT + heartbeat 10s，日誌 warn，cache_file 開咗；clmi.yaml 經 YAML 解析，Hy2 係 `up/down: "500 Mbps"`
- `HY_MBPS` 環境變數、預設 1000 兩種路徑都測過

**未喺真伺服器上跑過。** 建議先喺一台機試，跑完 `sing-box check` 同測速，確認無問題先再用喺其他機。

## 唔適用

- 大阪 96 號機：佢係 argosbx（`/root/agsbx/`），唔係 `/etc/s-box`，呢份唔啱用。
- 唔包括 VLESS+XHTTP：原版 sing-box 1.14.4 唔支援 XHTTP transport，呢份無加，亦唔應該加。
- 上游更新後要重新打補丁：用 `patch_sb.py` 對住新版上游 `sb.sh` 再跑一次就得。
