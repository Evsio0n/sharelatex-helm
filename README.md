# ShareLaTeX Helm Chart with Auto-Build (amd64)

这个项目包含了一个自定义的ShareLaTeX Docker镜像以及对应的Kubernetes Helm配置。

## 中文字体

项目使用了[Haixing-Hu/latex-chinese-fonts](https://github.com/Haixing-Hu/latex-chinese-fonts)的字体文件.

## 部署教程

[实验在 Kubernetes 上部署 ShareLaTeX 并启用中文支持](https://evsio0n.com/archives/95/)

## 🔄 自动构建

项目配置了GitHub Actions自动构建流程：

### 触发条件
- **每日构建**：每天UTC时间02:00（北京时间10:00）自动触发
- **代码推送**：当Dockerfile或构建配置发生变化时触发
- **手动触发**：可以在GitHub Actions页面手动触发

### 构建产物

每次构建会生成以下产物：

1. **Docker镜像**：推送到GitHub Container Registry
   - 镜像地址：`ghcr.io/evsio0n/helm-sharelatex/sharelatex-custom`
   - 标签格式：`YYYYMMDD` (日期标签)

2. **Artifacts**：
   - `build-report-{run_number}`：构建报告文档

## 🚀 使用方法

### 1. 从Registry拉取镜像 (amd64)

```bash
# 拉取最新的每日构建镜像 (amd64)
docker pull --platform linux/amd64 ghcr.io/你的用户名/helm-sharelatex/sharelatex-custom:$(date +%Y%m%d)

# 或者拉取特定日期的镜像
docker pull --platform linux/amd64 ghcr.io/你的用户名/helm-sharelatex/sharelatex-custom:20250725
```


### 2. 在Kubernetes中使用

更新你的Helm values文件中的镜像地址：

```yaml
image:
  repository: ghcr.io/evsio0n/helm-sharelatex/sharelatex-custom
  tag: "20250725"  # 使用对应日期的标签
nodeSelector:
  kubernetes.io/arch: amd64  # 确保调度到amd64节点
```

## 📝 自定义配置

### 修改构建时间

编辑 `.github/workflows/daily-build.yml` 文件中的cron表达式：

```yaml
schedule:
  - cron: '0 2 * * *'  # 修改为你想要的时间
```

### 添加构建通知

可以在workflow中添加通知步骤，例如发送到Slack或邮件。


## 🛠 开发



### 手动推送镜像

```bash
# 登录到GitHub Container Registry
echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin

# 构建并推送 (amd64)
docker build --platform linux/amd64 -t ghcr.io/你的用户名/helm-sharelatex/sharelatex-custom:manual .
docker push ghcr.io/你的用户名/helm-sharelatex/sharelatex-custom:manual
```

## 📊 监控构建状态

- 访问项目的GitHub Actions页面查看构建历史
- 查看构建报告了解详细信息
- 监控artifact使用情况和存储空间

## 🔧 故障排除

### 构建失败
1. 检查Dockerfile语法
2. 查看GitHub Actions日志
3. 确认Registry权限设置正确

### 权限问题
确保GitHub仓库设置中启用了：
- Actions权限
- Packages权限（用于推送到Container Registry）

## 📄 许可证
需要留意 [微软字体许可FAQ](https://learn.microsoft.com/en-us/typography/fonts/font-faq)

