# OpenClaw 跨系统一键安装

本目录提供两种分发方式：

- 直接运行安装脚本（本地仓库方式）
- 生成一个“通用安装包”（给最终用户下载）
- 生成 Windows Inno Setup 安装程序（推荐 Windows 用户）
- 提供统一下载链接（自动识别系统跳转）

## 统一下载链接（主推）

推荐对外只提供一个链接（GitHub Pages）：

- `https://<owner>.github.io/<repo>/download/`

跳转规则：

- Windows：自动跳转到 `openclaw-installer-windows-setup.exe`
- macOS / Linux：自动跳转到 `openclaw-installer-universal.zip`

页面中也会提供手动下载按钮作为兜底。

本地预览时可附加参数指定仓库：

- `.../download/?repo=<owner>/<repo>`

## 通用安装包（推荐给用户）

执行后会生成：

- `dist/openclaw-installer-universal.zip`

包内包含 Windows/macOS/Linux 启动器，用户解压后按系统运行：

- Windows：`Start-Installer.cmd`
- Linux：`start-installer.sh`
- macOS：`start-installer.command`

启动后不需要用户选择系统，会自动识别当前系统并执行对应安装脚本。

## 给最终用户的最短路径

1. 下载 `openclaw-installer-universal.zip`
2. 解压
3. 双击对应入口：
   - Windows：`Start-Installer.cmd`
   - macOS：`start-installer.command`
   - Linux：`start-installer.sh`

如果 macOS/Linux 提示没有执行权限，先执行：

```bash
chmod +x ./start-installer.sh ./start-installer.command ./install-openclaw.sh ./openclaw-installer-selector.sh ./openclaw-installer-selector.command
```

## 本地生成安装包

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build-universal-package.ps1
```

本地生成后，直接把 `dist/openclaw-installer-universal.zip` 分发给用户即可。

## Windows Inno Setup 安装程序（.exe）

生成后会得到：

- `dist/openclaw-installer-windows-setup.exe`

用户下载后直接双击运行，安装器会自动按当前 Windows 系统执行 OpenClaw 安装流程，无需手动选择系统。

本地构建命令：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build-inno-package.ps1
```

## GitHub Actions 生成安装包

1. 进入 `Actions`
2. 选择 `release-installers`（推荐，直接发 Release 资产）
3. 输入版本号（如 `1.0.0`）并运行
4. 在 `Releases` 中获取：
   - `openclaw-installer-windows-setup.exe`
   - `openclaw-installer-universal.zip`

也可使用：

- `build-universal-package`（只构建通用 zip）
- `build-windows-inno-package`（只构建 Windows exe）

## GitHub Pages 部署统一下载页

1. 进入 `Actions`
2. 选择 `deploy-download-page`
3. 点击 `Run workflow`
4. 在仓库 `Settings -> Pages` 确认来源为 `Deploy from a branch`，分支选择 `gh-pages`（`/root`）
5. 对外使用统一下载链接：`https://<owner>.github.io/<repo>/download/`

## 一键推送并触发发布（推荐）

如果你希望尽量自动化（推送代码 + 触发 Release + 部署下载页），可直接运行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\publish-and-dispatch.ps1 -RepoUrl "https://github.com/<owner>/<repo>.git" -Version "1.0.0"
```

如果想自动触发两个 workflow（无需手动点 Actions），再加 `GithubToken`：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\publish-and-dispatch.ps1 -RepoUrl "https://github.com/<owner>/<repo>.git" -Version "1.0.0" -GithubToken "<github_pat_or_token>"
```

## 关键文件

- `scripts/build-universal-package.ps1`：通用安装包构建脚本
- `scripts/build-inno-package.ps1`：Windows Inno Setup 安装程序构建脚本
- `.github/workflows/build-universal-package.yml`：安装包构建工作流
- `.github/workflows/build-windows-inno-package.yml`：Windows Inno Setup 构建工作流
- `.github/workflows/release-installers.yml`：一键构建并发布 Release 资产
- `.github/workflows/deploy-download-page.yml`：部署统一下载页到 GitHub Pages
- `inno/openclaw-windows-installer.iss`：Inno Setup 安装脚本
- `docs/download/index.html`：统一下载页（自动识别系统跳转）
- `openclaw-installer-selector.cmd`：Windows 自动系统识别入口
- `openclaw-installer-selector.sh`：Linux 自动系统识别入口
- `openclaw-installer-selector.command`：macOS 自动系统识别入口
- `一键安装OpenClaw-系统选择.*`：兼容入口（转调 ASCII 入口）
- `install-openclaw.ps1`：Windows 安装器
- `install-openclaw.sh`：macOS/Linux 安装器

## 三系统安装测试

保留现有 smoke test 工作流：

- `.github/workflows/installers-smoke-test.yml`

测试模式变量：

- `OPENCLAW_TEST_MODE=1`
- `OPENCLAW_NONINTERACTIVE=1`
- `OPENCLAW_SELECTOR_CHOICE=auto`
