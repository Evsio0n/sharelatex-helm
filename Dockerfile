FROM sharelatex/sharelatex:latest

# 1. 配置 Tex Live 的包管理器使用国内清华源的代理
# 2. 安装 `scheme-full` 表示的绝大多数宏包
# 3. 安装 fandol 中文字体
RUN tlmgr install scheme-full && \
    tlmgr install fandol
# 安装textlive-full
RUN apt update && apt-get install -y texlive-full 