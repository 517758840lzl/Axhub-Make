#!/bin/zsh
set -euo pipefail

cd "$HOME"

# 保证双击时也能找到 Homebrew / nvm 的 node、npx
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
if [ -s "$HOME/.nvm/nvm.sh" ]; then
  # shellcheck disable=SC1091
  . "$HOME/.nvm/nvm.sh"
fi
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

echo "========================================"
echo "  Axhub Make"
echo "========================================"
echo "Node: $(command -v node || echo 未找到)  $(node -v 2>/dev/null || true)"
echo "npx:  $(command -v npx || echo 未找到)"
echo
echo "启动后请在本窗口查找访问地址（一般为 http://127.0.0.1:端口 或 http://localhost:端口）"
echo "不要关闭本窗口。结束请按 Ctrl+C。"
echo "========================================"
echo

exec npx -y @axhub/make@latest
