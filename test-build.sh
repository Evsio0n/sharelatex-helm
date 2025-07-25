#!/bin/bash

# 简单的构建测试脚本，用于GitHub Actions中的错误排查

echo "=== ShareLaTeX Docker 构建测试 ==="

# 检查基础镜像
echo "1. 拉取基础镜像..."
docker pull sharelatex/sharelatex:latest

# 测试基础镜像的tlmgr
echo "2. 测试基础镜像中的tlmgr..."
docker run --rm sharelatex/sharelatex:latest bash -c "
    echo 'TeX Live版本:'
    tex --version | head -n1
    echo 'tlmgr版本:'
    tlmgr --version
    echo '当前仓库:'
    tlmgr option repository || echo 'repository option failed'
    echo '测试网络连接:'
    curl -I https://mirrors.tuna.tsinghua.edu.cn/CTAN/systems/texlive/tlnet/ || echo 'Network test failed'
"

# 逐步测试Dockerfile的每个阶段
echo "3. 测试Dockerfile第一阶段..."
cat > Dockerfile.test1 << 'EOF'
FROM sharelatex/sharelatex:latest
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y wget curl && rm -rf /var/lib/apt/lists/*
RUN echo "Stage 1 completed successfully"
EOF

docker build -f Dockerfile.test1 -t sharelatex-test1 . || { echo "Stage 1 failed"; exit 1; }

echo "4. 测试tlmgr配置..."
cat > Dockerfile.test2 << 'EOF'
FROM sharelatex/sharelatex:latest
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y wget curl && rm -rf /var/lib/apt/lists/*
RUN tlmgr option repository https://mirrors.tuna.tsinghua.edu.cn/CTAN/systems/texlive/tlnet && \
    echo "Repository configured" && \
    tlmgr option repository
EOF

docker build -f Dockerfile.test2 -t sharelatex-test2 . || { echo "Stage 2 failed"; exit 1; }

echo "5. 测试tlmgr update..."
cat > Dockerfile.test3 << 'EOF'
FROM sharelatex/sharelatex:latest
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y wget curl && rm -rf /var/lib/apt/lists/*
RUN tlmgr option repository https://mirrors.tuna.tsinghua.edu.cn/CTAN/systems/texlive/tlnet && \
    tlmgr update --self || echo "tlmgr self-update failed"
EOF

docker build -f Dockerfile.test3 -t sharelatex-test3 . || { echo "Stage 3 failed"; exit 1; }

echo "6. 测试安装单个包..."
cat > Dockerfile.test4 << 'EOF'
FROM sharelatex/sharelatex:latest
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y wget curl && rm -rf /var/lib/apt/lists/*
RUN tlmgr option repository https://mirrors.tuna.tsinghua.edu.cn/CTAN/systems/texlive/tlnet && \
    tlmgr update --self || echo "tlmgr self-update failed" && \
    tlmgr install fandol || echo "fandol installation failed"
EOF

docker build -f Dockerfile.test4 -t sharelatex-test4 . || { echo "Stage 4 failed"; exit 1; }

echo "=== 所有测试阶段完成 ==="

# 清理测试文件
rm -f Dockerfile.test*

echo "测试完成！如果所有阶段都成功，那么原始Dockerfile应该也能工作。"
