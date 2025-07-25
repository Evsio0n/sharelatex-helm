#!/bin/bash

# amd64架构验证脚本

echo "=== ShareLaTeX amd64 架构验证 ==="
echo ""

echo "1. 检查当前系统架构:"
uname -m
echo ""

echo "2. 检查Docker信息:"
docker version --format '{{.Server.Arch}}' 2>/dev/null || echo "Docker未运行"
echo ""

echo "3. 验证基础镜像架构:"
if docker images -q sharelatex/sharelatex:latest > /dev/null 2>&1; then
    docker inspect sharelatex/sharelatex:latest | grep -A2 "Architecture" || echo "无法获取架构信息"
else
    echo "基础镜像未找到，尝试拉取..."
    docker pull --platform linux/amd64 sharelatex/sharelatex:latest
fi
echo ""

echo "4. 检查本地构建的镜像(如果存在):"
if docker images -q sharelatex-custom:latest > /dev/null 2>&1; then
    echo "找到本地构建的镜像:"
    docker inspect sharelatex-custom:latest | grep -A2 "Architecture" || echo "无法获取架构信息"
    docker images sharelatex-custom
else
    echo "本地尚未构建镜像"
fi
echo ""

echo "=== 架构兼容性检查完成 ==="
echo ""
echo "如果所有检查都显示 amd64/x86_64，那么配置是正确的。"
