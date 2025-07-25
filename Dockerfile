FROM sharelatex/sharelatex:latest

# 设置环境变量避免交互式安装
ENV DEBIAN_FRONTEND=noninteractive

# 1. 更新系统包（amd64优化）
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# 2. 配置 TeX Live 包管理器（amd64专用优化）
RUN echo "配置TeX Live仓库..." && \
    tlmgr update --self

# 3. 安装中文字体（针对amd64优化的安装顺序）
RUN echo "安装fandol中文字体..." && \
    tlmgr install fandol

# 4. 安装中文支持包（amd64稳定版本）
RUN echo "安装中文支持包..." && \
    tlmgr install ctex xecjk cjk cjkpunct zhmetrics zhnumber

# 5. 安装数学包
RUN echo "安装数学包..." && \
    tlmgr install amsmath amsfonts amssymb

# 6. 安装图形和排版包
RUN echo "安装图形和排版包..." && \
    tlmgr install graphicx geometry hyperref xcolor

# 7. 安装绘图包
RUN echo "安装绘图包..." && \
    tlmgr install tikz pgf

# 8. 安装表格包
RUN echo "安装表格包..." && \
    tlmgr install booktabs multirow longtable array

# 9. 安装其他实用包
RUN echo "安装其他实用包..." && \
    tlmgr install ulem listings caption subcaption float

# 10. 验证安装并显示信息
RUN echo "=== 安装验证 ===" && \
    latex --version | head -n1 && \
    xelatex --version | head -n1 && \
    echo "已安装的TeX Live包数量:" && \
    tlmgr list --installed | wc -l && \
    echo "=== amd64构建完成 ===" 