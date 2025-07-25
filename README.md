# ShareLaTeX Helm Chart with Auto-Build

这个项目包含了一个自定义的ShareLaTeX Docker镜像以及对应的Kubernetes Helm配置。

## 🔄 自动构建

项目配置了GitHub Actions自动构建流程：

### 触发条件
- **每日构建**：每天UTC时间02:00（北京时间10:00）自动触发
- **代码推送**：当Dockerfile或构建配置发生变化时触发
- **手动触发**：可以在GitHub Actions页面手动触发

### 构建产物

每次构建会生成以下产物：

1. **Docker镜像**：推送到GitHub Container Registry
   - 镜像地址：`ghcr.io/你的用户名/helm-sharelatex/sharelatex-custom`
   - 标签格式：`YYYYMMDD` (日期标签)

2. **Artifacts**：
   - `sharelatex-docker-image-{run_number}`：压缩的Docker镜像tar文件
   - `build-report-{run_number}`：构建报告文档

## 🚀 使用方法

### 1. 从Registry拉取镜像

```bash
# 拉取最新的每日构建镜像
docker pull ghcr.io/你的用户名/helm-sharelatex/sharelatex-custom:$(date +%Y%m%d)

# 或者拉取特定日期的镜像
docker pull ghcr.io/你的用户名/helm-sharelatex/sharelatex-custom:20250725
```

### 2. 从Artifacts下载镜像

1. 访问项目的GitHub Actions页面
2. 选择对应的构建运行
3. 下载 `sharelatex-docker-image-*` artifact
4. 解压并加载镜像：

```bash
# 解压
gunzip sharelatex-image-YYYYMMDD.tar.gz

# 加载到Docker
docker load -i sharelatex-image-YYYYMMDD.tar
```

### 3. 在Kubernetes中使用

更新你的Helm values文件中的镜像地址：

```yaml
image:
  repository: ghcr.io/你的用户名/helm-sharelatex/sharelatex-custom
  tag: "20250725"  # 使用对应日期的标签
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

### 多平台构建

当前配置支持 `linux/amd64` 和 `linux/arm64` 平台，可以根据需要调整。

## 🛠 开发

### 本地测试构建

```bash
# 构建镜像
docker build -t sharelatex-custom .

# 测试运行
docker run -d -p 80:80 sharelatex-custom
```

### 手动推送镜像

```bash
# 登录到GitHub Container Registry
echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin

# 构建并推送
docker build -t ghcr.io/你的用户名/helm-sharelatex/sharelatex-custom:manual .
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

请根据你的需要添加合适的许可证文件。
