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
    echo "  help      - 显示此帮助信息"
}

build_image() {
    echo -e "${YELLOW}正在构建Docker镜像...${NC}"
    docker build -t ${IMAGE_NAME}:${DATE_TAG} -t ${IMAGE_NAME}:latest .
    echo -e "${GREEN}✅ 镜像构建完成: ${IMAGE_NAME}:${DATE_TAG}${NC}"
}

test_image() {
    echo -e "${YELLOW}启动测试容器...${NC}"
    
    # 停止可能存在的测试容器
    docker stop sharelatex-test 2>/dev/null || true
    docker rm sharelatex-test 2>/dev/null || true
    
    # 启动新的测试容器
    docker run -d --name sharelatex-test -p 8080:80 ${IMAGE_NAME}:latest
    
    echo -e "${GREEN}✅ 测试容器已启动${NC}"
    echo -e "${BLUE}访问地址: http://localhost:8080${NC}"
    echo -e "${YELLOW}使用 'docker logs sharelatex-test' 查看日志${NC}"
    echo -e "${YELLOW}使用 'docker stop sharelatex-test' 停止测试${NC}"
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
    echo -e "${BLUE}当前状态:${NC}"
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
    echo ""
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
    "help"|*)
        print_usage
        ;;
esac
