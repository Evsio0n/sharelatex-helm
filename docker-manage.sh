#!/bin/bash

# ShareLaTeX Docker 构建和管理脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置
IMAGE_NAME="sharelatex-custom"
REGISTRY="ghcr.io"
DATE_TAG=$(date +%Y%m%d)

print_header() {
    echo -e "${BLUE}===================================================${NC}"
    echo -e "${BLUE}  ShareLaTeX Docker 构建管理工具${NC}"
    echo -e "${BLUE}===================================================${NC}"
}

print_usage() {
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  build     - 本地构建Docker镜像"
    echo "  test      - 测试运行镜像"
    echo "  push      - 推送镜像到registry"
    echo "  pull      - 从registry拉取最新镜像"
    echo "  clean     - 清理本地镜像"
    echo "  status    - 显示当前状态"
    echo "  debug     - 调试构建问题"
    echo "  logs      - 查看最近的构建日志"
    echo "  help      - 显示此帮助信息"
}

build_image() {
    echo -e "${YELLOW}正在构建Docker镜像 (amd64)...${NC}"
    echo -e "${BLUE}提示: 针对amd64平台优化，构建过程可能需要10-15分钟${NC}"
    
    # 添加详细的构建日志，针对amd64优化
    if docker build --platform linux/amd64 --progress=plain -t ${IMAGE_NAME}:${DATE_TAG} -t ${IMAGE_NAME}:latest . 2>&1 | tee build.log; then
        echo -e "${GREEN}✅ amd64镜像构建完成: ${IMAGE_NAME}:${DATE_TAG}${NC}"
        
        # 显示镜像信息
        echo -e "${BLUE}镜像详情:${NC}"
        docker images | grep ${IMAGE_NAME}
        
        # 显示镜像架构信息
        echo -e "${BLUE}镜像架构信息:${NC}"
        docker inspect ${IMAGE_NAME}:latest | grep -A5 -B5 "Architecture" || echo "无法获取架构信息"
    else
        echo -e "${RED}❌ 镜像构建失败${NC}"
        echo -e "${YELLOW}请检查 build.log 文件获取详细错误信息${NC}"
        exit 1
    fi
}

test_image() {
    echo -e "${YELLOW}启动测试容器 (amd64)...${NC}"
    
    # 停止可能存在的测试容器
    docker stop sharelatex-test 2>/dev/null || true
    docker rm sharelatex-test 2>/dev/null || true
    
    # 启动新的测试容器，明确指定平台
    docker run -d --name sharelatex-test --platform linux/amd64 -p 8080:80 ${IMAGE_NAME}:latest
    
    echo -e "${GREEN}✅ 测试容器已启动 (amd64)${NC}"
    echo -e "${BLUE}访问地址: http://localhost:8080${NC}"
    echo -e "${YELLOW}使用 'docker logs sharelatex-test' 查看日志${NC}"
    echo -e "${YELLOW}使用 'docker stop sharelatex-test' 停止测试${NC}"
    
    # 显示容器信息
    echo -e "${BLUE}容器信息:${NC}"
    docker inspect sharelatex-test | grep -A3 "Platform\|Architecture" || echo "平台信息: linux/amd64"
}

push_image() {
    if [ -z "$GITHUB_TOKEN" ]; then
        echo -e "${RED}❌ 错误: 请设置GITHUB_TOKEN环境变量${NC}"
        echo "export GITHUB_TOKEN=your_github_token"
        exit 1
    fi
    
    echo -e "${YELLOW}登录到GitHub Container Registry...${NC}"
    echo $GITHUB_TOKEN | docker login ghcr.io -u $USER --password-stdin
    
    echo -e "${YELLOW}推送镜像到registry...${NC}"
    # 需要手动替换为你的GitHub用户名和仓库名
    FULL_IMAGE="${REGISTRY}/your-username/helm-sharelatex/${IMAGE_NAME}"
    
    docker tag ${IMAGE_NAME}:${DATE_TAG} ${FULL_IMAGE}:${DATE_TAG}
    docker tag ${IMAGE_NAME}:latest ${FULL_IMAGE}:latest
    
    docker push ${FULL_IMAGE}:${DATE_TAG}
    docker push ${FULL_IMAGE}:latest
    
    echo -e "${GREEN}✅ 镜像推送完成${NC}"
}

pull_image() {
    echo -e "${YELLOW}从registry拉取最新镜像...${NC}"
    FULL_IMAGE="${REGISTRY}/your-username/helm-sharelatex/${IMAGE_NAME}"
    
    docker pull ${FULL_IMAGE}:latest
    docker tag ${FULL_IMAGE}:latest ${IMAGE_NAME}:latest
    
    echo -e "${GREEN}✅ 镜像拉取完成${NC}"
}

clean_images() {
    echo -e "${YELLOW}清理本地镜像...${NC}"
    
    # 停止并删除测试容器
    docker stop sharelatex-test 2>/dev/null || true
    docker rm sharelatex-test 2>/dev/null || true
    
    # 删除本地镜像
    docker rmi ${IMAGE_NAME}:latest ${IMAGE_NAME}:${DATE_TAG} 2>/dev/null || true
    
    # 清理悬空镜像
    docker image prune -f
    
    echo -e "${GREEN}✅ 清理完成${NC}"
}

show_status() {
    echo -e "${BLUE}当前状态 (amd64专用版本):${NC}"
    echo ""
    
    echo -e "${YELLOW}本地镜像:${NC}"
    docker images | grep -E "(${IMAGE_NAME}|REPOSITORY)" || echo "  无相关镜像"
    echo ""
    
    echo -e "${YELLOW}运行中的容器:${NC}"
    docker ps | grep -E "(sharelatex|CONTAINER)" || echo "  无相关容器"
    echo ""
    
    echo -e "${YELLOW}构建信息:${NC}"
    echo "  日期标签: ${DATE_TAG}"
    echo "  镜像名称: ${IMAGE_NAME}"
    echo "  目标架构: linux/amd64"
    echo "  当前系统: $(uname -m)"
    echo ""
    
    # 检查是否有镜像
    if docker images | grep -q ${IMAGE_NAME}; then
        echo -e "${YELLOW}镜像架构信息:${NC}"
        docker inspect ${IMAGE_NAME}:latest 2>/dev/null | grep -A2 "Architecture" || echo "  无法获取镜像架构信息"
    fi
}

debug_build() {
    echo -e "${YELLOW}开始调试构建过程 (amd64)...${NC}"
    echo ""
    
    echo -e "${BLUE}1. 检查基础镜像 (amd64)...${NC}"
    docker pull --platform linux/amd64 sharelatex/sharelatex:latest
    
    echo -e "${BLUE}2. 测试基础镜像运行 (amd64)...${NC}"
    docker run --rm --platform linux/amd64 sharelatex/sharelatex:latest tlmgr --version || echo "tlmgr 不可用"
    
    echo -e "${BLUE}3. 逐步构建测试 (amd64)...${NC}"
    cat > Dockerfile.debug << 'EOF'
FROM sharelatex/sharelatex:latest

# 测试基本命令 (amd64优化)
RUN echo "=== 测试 tlmgr (amd64) ===" && \
    tlmgr --version && \
    echo "=== 测试网络连接 ===" && \
    curl -I https://mirrors.tuna.tsinghua.edu.cn/CTAN/systems/texlive/tlnet/ || true && \
    echo "=== 测试仓库设置 ===" && \
    tlmgr option repository https://mirrors.tuna.tsinghua.edu.cn/CTAN/systems/texlive/tlnet && \
    tlmgr option repository && \
    echo "=== 更新 tlmgr ===" && \
    tlmgr update --self && \
    echo "=== amd64 调试阶段完成 ==="
EOF
    
    echo -e "${YELLOW}构建调试镜像 (amd64)...${NC}"
    docker build --platform linux/amd64 -f Dockerfile.debug -t sharelatex-debug .
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ 调试构建成功 (amd64)${NC}"
        echo -e "${BLUE}运行调试容器检查环境...${NC}"
        docker run --rm --platform linux/amd64 sharelatex-debug bash -c "
            echo '=== TeX Live 版本 ==='
            tex --version | head -n1
            echo '=== tlmgr 配置 ==='
            tlmgr option repository
            echo '=== 可用包示例 ==='
            tlmgr info fandol | head -n5
            echo '=== 系统架构 ==='
            uname -m
        "
    else
        echo -e "${RED}❌ 调试构建失败${NC}"
    fi
    
    # 清理调试文件
    rm -f Dockerfile.debug
}

show_logs() {
    if [ -f "build.log" ]; then
        echo -e "${BLUE}最近的构建日志:${NC}"
        echo "========================="
        tail -n 50 build.log
        echo "========================="
        echo -e "${YELLOW}完整日志请查看 build.log 文件${NC}"
    else
        echo -e "${YELLOW}没有找到构建日志文件${NC}"
    fi
}

# 主逻辑
print_header

case "${1:-help}" in
    "build")
        build_image
        ;;
    "test")
        test_image
        ;;
    "push")
        push_image
        ;;
    "pull")
        pull_image
        ;;
    "clean")
        clean_images
        ;;
    "status")
        show_status
        ;;
    "debug")
        debug_build
        ;;
    "logs")
        show_logs
        ;;
    "help"|*)
        print_usage
        ;;
esac
