#!/bin/bash


exec > >(tee /root/.setup.log) 2>&1

IST_TIME=$(TZ=Asia/Kolkata date '+%Y-%m-%d  |  %H:%M:%S IST')
echo "=====  NEW SESSION START: $IST_TIME  ====="



# =========================
# STEP 1 (rclone install)
# =========================
echo "Step 1: Installing rclone..."
curl https://rclone.org/install.sh | bash
echo "Step 1 done ✅"

# =========================
# STEP 2 (ngrok install)
# =========================
echo "Step 2: Installing ngrok..."
if [ ! -f /etc/apt/sources.list.d/ngrok.list ]; then
  curl -sSL https://ngrok-agent.s3.amazonaws.com/ngrok.asc \
    | tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null

  echo "deb https://ngrok-agent.s3.amazonaws.com bookworm main" \
    | tee /etc/apt/sources.list.d/ngrok.list >/dev/null
fi

apt update
apt install ngrok -y
echo "Step 2 done ✅"

# =========================
# STEP 3 (ngrok auth)
# =========================
echo "Step 3: Setting ngrok auth..."
ngrok config add-authtoken 3BUgsLPlnWzktCjljsxfLZtmR3L_f78UwzLfhZQ1gKB1sq9N
echo "Step 3 done ✅"

# =========================
# STEP 4 (append cst/cstr safely)
# =========================
echo "Step 4: Adding WebDAV functions safely..."
ADD_CST=true
ADD_CSTR=true

grep -q "^cst()" ~/.bashrc && ADD_CST=false
grep -q "^cstr()" ~/.bashrc && ADD_CSTR=false

if $ADD_CST || $ADD_CSTR; then
  echo "" >> ~/.bashrc
  echo "# ===== CUSTOM WEBDAV + NGROK =====" >> ~/.bashrc

  if $ADD_CST; then
    cat << 'EOF' >> ~/.bashrc
cst() {
  PORT=${1:-8200}
  DIR="$(pwd)"
  echo "Dir: $DIR | Port: $PORT"
  rclone serve webdav "$DIR" --addr :$PORT --vfs-cache-mode writes --user hg --pass 'hg@76889' &
  until lsof -i :$PORT >/dev/null 2>&1; do sleep 1; done
  echo "Starting ngrok..."
  ngrok http $PORT
}
EOF
  fi

  if $ADD_CSTR; then
    cat << 'EOF' >> ~/.bashrc
cstr() {
  PORT=${1:-8200}
  DIR="$(pwd)"
  echo "Resetting port $PORT..."
  kill -9 $(lsof -t -i:$PORT) 2>/dev/null
  echo "Starting fresh WebDAV..."
  rclone serve webdav "$DIR" --addr :$PORT --vfs-cache-mode writes --user hg --pass 'hg@76889' &
  until lsof -i :$PORT >/dev/null 2>&1; do sleep 1; done
  echo "Starting ngrok..."
  ngrok http $PORT
}
EOF
  fi
  echo "# ===== END WEBDAV =====" >> ~/.bashrc
fi
echo "Step 4 done ✅"

# =========================
# STEP 5 (Ollama + Aliases)
# =========================
echo "Step 5: Adding Aliases and olsp function..."

ADD_OLSP=true
grep -q "^olsp()" ~/.bashrc && ADD_OLSP=false

if $ADD_OLSP; then
  cat << 'EOF' >> ~/.bashrc

# ----------------- Aliases ------------------
alias nb='nano ~/.bashrc'
alias sb='source ~/.bashrc'
alias ols='OLLAMA_HOST=0.0.0.0:11434 OLLAMA_ORIGINS="*" ollama serve'

# ----------------- olsp (Ollama + LocalTunnel) ------------------
olsp() {
  echo "🛑 Killing existing Ollama processes..."
  pkill ollama 2>/dev/null
  echo "🚀 Starting LocalTunnel on port 11434..."
  if ! command -v lt >/dev/null; then
    echo "❌ LocalTunnel (lt) not installed!"
    return 1
  fi
  lt --port 11434 --subdomain hollama-hgwebs-11434 &
  LT_PID=$!
  echo "⏳ Waiting 3 seconds for LocalTunnel to initialize..."
  sleep 3
  echo "🔍 Checking LocalTunnel status..."
  if ps -p $LT_PID > /dev/null; then
    echo "✅ LocalTunnel is running!"
  else
    echo "❌ LocalTunnel failed to start!"
    return 1
  fi
  echo "⚙️ Starting Ollama server..."
  OLLAMA_HOST=0.0.0.0:11434 OLLAMA_ORIGINS="*" ollama serve
}

# -------------  ollama shortcuts --------------
or() {
  if [ -z "$1" ]; then
    echo "Use: or <model>"
    return 1
  fi
  ollama run "$@"
}

op() {
  if [ -z "$1" ]; then
    echo "Use: op <model>"
    return 1
  fi
  ollama pull "$@"
}

# ----------  others - write here ------------


EOF
else
  echo "⚠️ olsp already exists → skipped"
fi
echo "Step 5 done ✅"

# =========================
# STEP 6 (Strict Package Installs)
# =========================
echo "Step 6: Installing Curl, Node.js & LocalTunnel..."

# Installing one by one and waiting for each to finish

apt install pciutils -y && \
apt install nano -y && \
apt install zstd -y && \
apt install -y nvidia-utils-535 -y && \
apt install nodejs npm -y && \
npm install -g localtunnel

# Final check for LocalTunnel
if ! command -v lt >/dev/null; then
    echo "Verifying installation..."
    sleep 2
fi

echo "Step 6 done ✅"

# =========================
# STEP 7 (Ollama Install - No Internet if Exists)
# =========================
echo "Step 7: Checking Ollama..."

if command -v ollama >/dev/null 2>&1; then
    echo "Ollama already installed ✅"
    ollama --version
    echo "Skipping download 🚫"
else
    echo "Ollama not found. Installing..."
    curl -fsSL https://ollama.com/install.sh | sh
    echo "Install done "
fi

echo "Step 7 done ✅"

# =========================
# DONE
# =========================
# Refresh shell
export PATH=$PATH:/usr/local/bin
source ~/.bashrc

echo "🚀 ALL DONE"
echo "👉 Commands ready: cst, cstr, olsp, nb, sb, ols"
