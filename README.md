# TerminalScript
A Linux terminal script, dreaming big.

## 功能
- 卸载阿里云监控组件（YunDun / CloudMonitor）。
- 为旧版 Debian 切换 APT 源（Debian 9/10，使用 Freexian ELTS）。
- 一键启用 BBR。

## 使用方法
使用 `wget`：
```
wget -N --no-check-certificate https://raw.githubusercontent.com/matthewlu070111/TerminalScript/main/tscript.sh && chmod 777 tscript.sh && ./tscript.sh
```

或使用 `curl`：
```
curl -fsSL https://raw.githubusercontent.com/matthewlu070111/TerminalScript/main/tscript.sh -o tscript.sh && chmod 777 tscript.sh && ./tscript.sh
```