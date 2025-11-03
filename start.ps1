# AM Downloader Start Script

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

param(
    [Parameter(Position=0, Mandatory=$false)]
    [ValidateSet("start", "stop", "download", "status", "logs", "clean", "help")]
    [string]$Action,
    
    [Parameter(Position=1, Mandatory=$false)]
    [string]$Url,
    
    [switch]$Song,
    [switch]$Atmos,
    [switch]$Aac,
    [switch]$Select,
    [switch]$ShowDebug,
    [switch]$AllAlbum
)

function Write-Title($text) {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  $text" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
}

function Write-Success($text) {
    Write-Host "✓ $text" -ForegroundColor Green
}

function Write-Error($text) {
    Write-Host "✗ $text" -ForegroundColor Red
}

function Write-Warning($text) {
    Write-Host "⚠ $text" -ForegroundColor Yellow
}

function Write-Info($text) {
    Write-Host "ℹ $text" -ForegroundColor Cyan
}

# 检查 Docker 状态
function Test-Docker {
    try {
        docker info 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "Docker 未运行，正在启动 Docker Desktop..."
            Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe"
            Write-Host "等待 Docker 启动（倒计时 15 秒）..." -ForegroundColor Yellow
            Start-Sleep -Seconds 15
            
            docker info 2>&1 | Out-Null
            if ($LASTEXITCODE -ne 0) {
                Write-Error "Docker 启动失败，请手动启动 Docker Desktop"
                return $false
            }
        }
        Write-Success "Docker 运行正常"
        return $true
    } catch {
        Write-Error "无法连接到 Docker"
        return $false
    }
}

# 启动服务
function Start-Services {
    Write-Title "启动 Wrapper 服务"
    
    # 检查目录
    if (-not (Test-Path "wrapper\wrapper")) {
        Write-Error "请在项目根目录运行此脚本！"
        Write-Host "当前目录: $(Get-Location)" -ForegroundColor Yellow
        pause
        return
    }
    
    # 检查 Docker
    Write-Host "[1/5] 检查 Docker 状态..." -ForegroundColor Green
    if (-not (Test-Docker)) {
        pause
        return
    }
    Write-Host ""
    
    # 检查镜像
    Write-Host "[2/5] 检查 Docker 镜像..." -ForegroundColor Green
    $imageExists = docker images -q apple-music-wrapper 2>$null
    if (-not $imageExists) {
        Write-Warning "未找到 apple-music-wrapper 镜像，正在构建..."
        Write-Host "这可能需要几分钟时间..." -ForegroundColor Yellow
        Push-Location wrapper
        docker build --tag apple-music-wrapper .
        Pop-Location
        if ($LASTEXITCODE -ne 0) {
            Write-Error "镜像构建失败"
            pause
            return
        }
        Write-Success "镜像构建成功"
    } else {
        Write-Success "镜像已存在"
    }
    Write-Host ""
    
    # 清理旧容器
    Write-Host "[3/5] 清理旧容器..." -ForegroundColor Green
    $oldContainer = docker ps -a -q --filter "name=apple-music-wrapper" 2>$null
    if ($oldContainer) {
        docker rm -f apple-music-wrapper 2>$null | Out-Null
        Write-Success "已清理旧容器"
    } else {
        Write-Success "无需清理"
    }
    Write-Host ""
    
    # 配置凭证
    Write-Host "[4/5] 配置登录凭证..." -ForegroundColor Green
    $credentialPath = "wrapper\rootfs\data\data\com.apple.android.music"
    $hasCredentials = Test-Path "$credentialPath\*"
    $needInteractiveLogin = $false
    
    if ($hasCredentials) {
        Write-Host "检测到本地凭证" -ForegroundColor Yellow
        $useExisting = Read-Host "是否使用本地凭证? (Y/n)"
        
        if ($useExisting -eq "" -or $useExisting -eq "Y" -or $useExisting -eq "y") {
            $loginArgs = "-H 0.0.0.0"
            Write-Success "使用本地凭证登录"
        } else {
            Write-Host "清除旧凭证..." -ForegroundColor Yellow
            Remove-Item -Path "$credentialPath\*" -Recurse -Force -ErrorAction SilentlyContinue
            
            Write-Host ""
            Write-Host "登录 Apple ID：" -ForegroundColor Cyan
            Write-Host "（Apple ID 需要拥有 Apple Music 订阅" -ForegroundColor Yellow
            Write-Host ""
            $email = Read-Host "Apple ID"
            $password = Read-Host "密码" -AsSecureString
            $passwordPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))
            
            $loginArgs = "-L ${email}:${passwordPlain} -H 0.0.0.0"
            $needInteractiveLogin = $true
            Write-Success "凭证配置完成（将使用交互模式登录）"
        }
    } else {
        Write-Host "首次使用须登录 Apple ID：" -ForegroundColor Cyan
        Write-Host "（Apple ID 需要拥有 Apple Music 订阅）" -ForegroundColor Yellow
        Write-Host ""
        $email = Read-Host "Apple ID"
        $password = Read-Host "密码" -AsSecureString
        $passwordPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))
        
        $loginArgs = "-L ${email}:${passwordPlain} -H 0.0.0.0"
        $needInteractiveLogin = $true
        Write-Success "凭证配置完成（将使用交互模式登录）"
    }
    Write-Host ""
    
    # 启动容器
    Write-Host "[5/5] 启动 Wrapper 容器..." -ForegroundColor Green
    $wrapperPath = Join-Path (Get-Location) "wrapper"
    
    if ($needInteractiveLogin) {
        Write-Host ""
        Write-Title "使用交互模式登录"
        Write-Host "注意事项：" -ForegroundColor Yellow
        Write-Host "1. 如果账号开启了双因素认证（2FA），验证码会发送到你的Apple设备" -ForegroundColor Yellow
        Write-Host "2. 请在下方提示时输入收到的验证码" -ForegroundColor Yellow
        Write-Host "3. 若长时间未收到验证码，尝试输入最后一次收到的验证码" -ForegroundColor Yellow
        Write-Host "4. 登录成功后容器会自动切换到后台运行" -ForegroundColor Yellow
        Write-Host ""
        Write-Info "Apple 验证码通常在几秒内送达，如超过1分钟未收到，"
        Write-Host "   可能是短时间内请求过多，建议等待15-30分钟后重试" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "按任意键继续..." -ForegroundColor Gray
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        Write-Host ""
        Write-Host "正在启动交互式登录..." -ForegroundColor Green
        Write-Host ""
        
        # 以交互模式启动
        docker run --rm -it --name apple-music-wrapper `
            -v "${wrapperPath}\rootfs\data:/app/rootfs/data" `
            -p 10020:10020 `
            -p 20020:20020 `
            -e args="$loginArgs" `
            apple-music-wrapper
        
        Write-Host ""
        Write-Host "交互式登录已完成，正在以后台模式重新启动..." -ForegroundColor Yellow
        
        # 验证成功后，以后台模式启动
        docker run -d --name apple-music-wrapper `
            -v "${wrapperPath}\rootfs\data:/app/rootfs/data" `
            -p 10020:10020 `
            -p 20020:20020 `
            -e args="-H 0.0.0.0" `
            apple-music-wrapper | Out-Null
        
        Start-Sleep -Seconds 3
    } else {
        # 使用已保存的凭证，后台启动
        Write-Host "使用已保存的凭证启动..." -ForegroundColor Yellow
        docker run -d --name apple-music-wrapper `
            -v "${wrapperPath}\rootfs\data:/app/rootfs/data" `
            -p 10020:10020 `
            -p 20020:20020 `
            -e args="$loginArgs" `
            apple-music-wrapper | Out-Null

        if ($LASTEXITCODE -ne 0) {
            Write-Error "容器启动失败"
            pause
            return
        }
        
        Start-Sleep -Seconds 3
    }
    
    # 检查容器状态
    $containerStatus = docker ps --filter "name=apple-music-wrapper" --format "{{.Status}}"
    if (-not $containerStatus) {
        Write-Error "容器未运行，查看日志："
        docker logs apple-music-wrapper 2>&1
        pause
        return
    }
    
    # 最终检查
    $finalLogs = docker logs apple-music-wrapper 2>&1 | Out-String
    if ($finalLogs -match "listening.*10020" -and $finalLogs -match "listening.*20020") {
        Write-Host ""
        Write-Title "Wrapper 启动成功！"
        Write-Host "解密端口: 127.0.0.1:10020" -ForegroundColor Cyan
        Write-Host "M3U8端口: 127.0.0.1:20020" -ForegroundColor Cyan
        Write-Host ""
    } else {
        Write-Warning "容器已启动，但服务状态未知"
        Write-Host "完整日志：" -ForegroundColor Yellow
        docker logs apple-music-wrapper 2>&1
        Write-Host ""
        Write-Host "如需重新登录:" -ForegroundColor Yellow
        Write-Host "  Remove-Item -Path `"wrapper\rootfs\data\data\com.apple.android.music\*`" -Recurse -Force" -ForegroundColor White
        Write-Host "  .\start.ps1 download [链接]" -ForegroundColor White
        Write-Host ""
    }
}

# 停止服务
function Stop-Services {
    Write-Title "停止 Wrapper 服务"
    
    $containerExists = docker ps -a -q --filter "name=apple-music-wrapper" 2>$null
    
    if (-not $containerExists) {
        Write-Info "未找到 apple-music-wrapper 容器"
        pause
        return
    }
    
    $containerStatus = docker ps --filter "name=apple-music-wrapper" --format "{{.Status}}"
    
    if ($containerStatus) {
        Write-Host "正在停止容器..." -ForegroundColor Yellow
        docker stop apple-music-wrapper | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Success "容器已停止"
        } else {
            Write-Error "停止容器失败"
        }
    } else {
        Write-Host "容器已经停止" -ForegroundColor Yellow
    }
    
    Write-Host ""
    $removeContainer = Read-Host "是否删除容器? (y/N)"
    
    if ($removeContainer -eq "Y" -or $removeContainer -eq "y") {
        docker rm apple-music-wrapper 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Success "容器已删除"
        }
    }
    
    Write-Host ""
    Write-Host "操作完成！" -ForegroundColor Green
    Write-Host ""
}

# 下载音乐
function Start-Download {
    param($Url, $Song, $Atmos, $Aac, $Select, $ShowDebug, $AllAlbum)
    
    Write-Title "AM 歌曲下载"
    
    # 检查 Wrapper 是否运行
    $wrapperStatus = docker ps --filter "name=apple-music-wrapper" --format "{{.Names}}"
    if (-not $wrapperStatus) {
        Write-Warning "Wrapper 服务未运行，正在自动启动..."
        Write-Host ""
        Start-Services
        Write-Host ""
        Write-Host "Wrapper 已启动，继续下载..." -ForegroundColor Green
        Write-Host ""
    }
    
    # 如果没有提供 URL，提示用户输入
    if (-not $Url) {
        Write-Host "请输入要下载的链接：" -ForegroundColor Yellow
        $Url = Read-Host "链接"
        
        if (-not $Url) {
            Write-Error "未提供链接"
            pause
            return
        }
        
        Write-Host ""
        Write-Host "选择已粘贴链接类型：" -ForegroundColor Yellow
        Write-Host "1. 单曲" -ForegroundColor White
        Write-Host "2. 完整专辑/播放列表" -ForegroundColor White
        Write-Host "3. 选择性下载" -ForegroundColor White
        Write-Host "4. 杜比全景声" -ForegroundColor White
        Write-Host "5. AAC 格式" -ForegroundColor White
        Write-Host "6. 查看音质信息" -ForegroundColor White
        Write-Host ""
        $choice = Read-Host "请选择 [1-6]"
        
        switch ($choice) {
            "1" { $Song = $true }
            "3" { $Select = $true }
            "4" { $Atmos = $true }
            "5" { $Aac = $true }
            "6" { $ShowDebug = $true }
        }
    }
    
    # 构建命令参数
    $cmdArgs = @()
    if ($Song) { $cmdArgs += "--song" }
    if ($Atmos) { $cmdArgs += "--atmos" }
    if ($Aac) { $cmdArgs += "--aac" }
    if ($Select) { $cmdArgs += "--select" }
    if ($ShowDebug) { $cmdArgs += "--debug" }
    if ($AllAlbum) { $cmdArgs += "--all-album" }
    $cmdArgs += $Url
    
    Write-Host ""
    
    # 创建下载目录（如果不存在）
    $downloadsPath = Join-Path (Get-Location) "AM-DL downloads"
    if (-not (Test-Path $downloadsPath)) {
        New-Item -ItemType Directory -Path $downloadsPath | Out-Null
    }
    
    # 检查下载器镜像是否存在
    $downloaderImageExists = docker images -q apple-music-downloader 2>$null
    if (-not $downloaderImageExists) {
        Write-Warning "首次使用需要构建下载器镜像..."
        Write-Host "这可能需要几分钟时间（仅首次）..." -ForegroundColor Yellow
        Write-Host "正在编译程序并安装依赖: Go + MP4Box + FFmpeg + mp4decrypt..." -ForegroundColor Cyan
        docker build -f Dockerfile.downloader -t apple-music-downloader .
        if ($LASTEXITCODE -ne 0) {
            Write-Error "下载器镜像构建失败"
            pause
            return
        }
        Write-Success "下载器镜像构建成功"
        Write-Host ""
    }
    
    Write-Host "开始下载..." -ForegroundColor Green
    Write-Host ""
    
    $configPath = Join-Path (Get-Location) "config.yaml"
    
    # 使用预编译的下载器容器（只挂载配置和下载目录）
    Write-Info "使用容器化下载器"
    
    # 在 Windows Docker Desktop 中，使用 host.docker.internal 访问宿主机
    # Wrapper 端口 10020 和 20020 已映射到宿主机
    # 将配置挂载为 config-host.yaml，入口脚本会复制并修改网络地址
    
    # 构建 docker run 命令（使用数组避免引号问题）
    $dockerArgs = @(
        "run", "--rm", "-it",
        "-v", "${downloadsPath}:/app/AM-DL downloads",
        "-v", "${configPath}:/app/config-host.yaml:ro",
        "-w", "/app",
        "apple-music-downloader"
    )
    
    # 添加下载参数
    $dockerArgs += $cmdArgs
    
    # 执行 docker 命令
    & docker $dockerArgs
    
    Write-Host ""
    if ($LASTEXITCODE -eq 0) {
        Write-Success "下载完成！"
        Write-Host ""
        Write-Host "文件保存在: AM-DL downloads\" -ForegroundColor Cyan
    } else {
        Write-Error "下载过程中出现错误"
    }
    Write-Host ""
}

# 查看状态
function Show-Status {
    Write-Title "服务状态"
    
    # 检查容器状态
    $containerStatus = docker ps --filter "name=apple-music-wrapper" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    
    if ($containerStatus -match "apple-music-wrapper") {
        Write-Success "Wrapper 服务运行中"
        Write-Host ""
        docker ps --filter "name=apple-music-wrapper" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
        Write-Host ""
        
        # 检查端口监听
        $logs = docker logs apple-music-wrapper 2>&1 | Out-String
        if ($logs -match "listening.*10020" -and $logs -match "listening.*20020") {
            Write-Success "端口监听正常"
            Write-Host "  解密端口: 127.0.0.1:10020" -ForegroundColor Cyan
            Write-Host "  M3U8端口: 127.0.0.1:20020" -ForegroundColor Cyan
        } else {
            Write-Warning "端口监听状态未知，请查看日志"
        }
    } else {
        Write-Warning "Wrapper 服务未运行"
        Write-Host "使用 .\start.ps1 download [链接] 自动启动并下载" -ForegroundColor Yellow
    }
    
    Write-Host ""
}

# 查看日志
function Show-Logs {
    Write-Title "服务日志"
    
    $containerExists = docker ps -a -q --filter "name=apple-music-wrapper" 2>$null
    if (-not $containerExists) {
        Write-Warning "未找到 apple-music-wrapper 容器"
        pause
        return
    }
    
    Write-Host "显示最近 50 行日志：" -ForegroundColor Cyan
    Write-Host ""
    docker logs --tail 50 apple-music-wrapper 2>&1
    Write-Host ""
    Write-Host "提示: 使用 'docker logs -f apple-music-wrapper' 查看实时日志" -ForegroundColor DarkGray
    Write-Host ""
}

# 清理系统
function Clear-DockerResources {
    Write-Title "清理 Docker 资源"
    
    Write-Host "清理选项：" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "1. 停止容器但保留镜像（推荐）" -ForegroundColor Cyan
    Write-Host "2. 删除所有容器和镜像" -ForegroundColor Cyan
    Write-Host "3. 完全清理（包括构建缓存）" -ForegroundColor Cyan
    Write-Host "0. 取消" -ForegroundColor Red
    Write-Host ""
    $cleanChoice = Read-Host "请选择 [0-3]"
    
    switch ($cleanChoice) {
        "1" {
            Write-Host ""
            Write-Host "正在停止并删除容器..." -ForegroundColor Yellow
            docker stop apple-music-wrapper 2>&1 | Out-Null
            docker rm apple-music-wrapper 2>&1 | Out-Null
            Write-Success "容器已清理"
            Write-Info "镜像已保留，下次启动更快"
        }
        "2" {
            Write-Host ""
            Write-Host "正在清理容器和镜像..." -ForegroundColor Yellow
            
            # 停止并删除容器
            Write-Host "  停止容器..." -ForegroundColor DarkGray
            docker stop apple-music-wrapper 2>&1 | Out-Null
            docker rm apple-music-wrapper 2>&1 | Out-Null
            
            # 删除镜像
            Write-Host "  删除镜像..." -ForegroundColor DarkGray
            docker rmi apple-music-wrapper 2>&1 | Out-Null
            docker rmi apple-music-downloader 2>&1 | Out-Null
            
            Write-Success "容器和镜像已清理"
            Write-Info "下次使用需要重新构建镜像"
        }
        "3" {
            Write-Host ""
            Write-Host "正在完全清理..." -ForegroundColor Yellow
            
            # 停止并删除容器
            Write-Host "  停止容器..." -ForegroundColor DarkGray
            docker stop apple-music-wrapper 2>&1 | Out-Null
            docker rm apple-music-wrapper 2>&1 | Out-Null
            
            # 删除镜像
            Write-Host "  删除镜像..." -ForegroundColor DarkGray
            docker rmi apple-music-wrapper 2>&1 | Out-Null
            docker rmi apple-music-downloader 2>&1 | Out-Null
            
            # 清理构建缓存
            Write-Host "  清理构建缓存..." -ForegroundColor DarkGray
            docker builder prune -f
            
            Write-Success "完全清理完成"
            Write-Info "已释放所有 Docker 资源"
        }
        "0" {
            Write-Info "已取消清理"
        }
        default {
            Write-Warning "无效的选择"
        }
    }
    
    Write-Host ""
}

# 显示帮助
function Show-Help {
    Write-Title "Apple Music Downloader 使用帮助"
    
    Write-Host "用法：" -ForegroundColor Yellow
    Write-Host "  .\start.ps1 [命令] [参数]" -ForegroundColor White
    Write-Host ""
    
    Write-Host "可用命令：" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  download [链接]    下载音乐（自动启动服务）" -ForegroundColor Cyan
    Write-Host "  status             查看服务状态" -ForegroundColor Cyan
    Write-Host "  logs               查看服务日志" -ForegroundColor Cyan
    Write-Host "  clean              清理 Docker 资源" -ForegroundColor Cyan
    Write-Host "  help               显示此帮助信息" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "💡 提示：" -ForegroundColor Yellow
    Write-Host "  • 无参数运行进入交互菜单" -ForegroundColor White
    Write-Host "  • 下载时会自动启动服务" -ForegroundColor White
    Write-Host "  • 退出时可选择清理方式" -ForegroundColor White
    Write-Host ""
    
    Write-Host "下载选项：" -ForegroundColor Yellow
    Write-Host "  -Song              下载单曲" -ForegroundColor White
    Write-Host "  -Atmos             下载杜比全景声版本" -ForegroundColor White
    Write-Host "  -Aac               下载 AAC 版本" -ForegroundColor White
    Write-Host "  -Select            选择性下载专辑曲目" -ForegroundColor White
    Write-Host "  -ShowDebug         查看音质信息" -ForegroundColor White
    Write-Host "  -AllAlbum          下载歌手所有专辑" -ForegroundColor White
    Write-Host ""
    
    Write-Host "示例：" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  # 进入交互菜单" -ForegroundColor DarkGray
    Write-Host "  .\start.ps1" -ForegroundColor White
    Write-Host ""
    Write-Host "  # 下载单曲" -ForegroundColor DarkGray
    Write-Host "  .\start.ps1 download -Song `"https://music.apple.com/cn/album/...?i=...`"" -ForegroundColor White
    Write-Host ""
    Write-Host "  # 下载专辑" -ForegroundColor DarkGray
    Write-Host "  .\start.ps1 download `"https://music.apple.com/cn/album/...`"" -ForegroundColor White
    Write-Host ""
    Write-Host "  # 下载杜比全景声" -ForegroundColor DarkGray
    Write-Host "  .\start.ps1 download -Atmos `"https://music.apple.com/cn/album/...`"" -ForegroundColor White
    Write-Host ""
    Write-Host "  # 查看服务状态" -ForegroundColor DarkGray
    Write-Host "  .\start.ps1 status" -ForegroundColor White
    Write-Host ""
    Write-Host "  # 清理系统" -ForegroundColor DarkGray
    Write-Host "  .\start.ps1 clean" -ForegroundColor White
    Write-Host ""
}

# 显示交互菜单
function Show-Menu {
    while ($true) {
        Clear-Host
        Write-Title "Apple Music Downloader"
        
        Write-Host "请选择操作：" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  1. 下载音乐" -ForegroundColor Cyan
        Write-Host "  2. 查看服务状态" -ForegroundColor Cyan
        Write-Host "  3. 查看日志" -ForegroundColor Cyan
        Write-Host "  4. 帮助" -ForegroundColor Cyan
        Write-Host "  0. 退出" -ForegroundColor Red
        Write-Host ""
        
        $choice = Read-Host "请选择 [0-4]"
        
        switch ($choice) {
            "1" { 
                Clear-Host
                Start-Download -Url $null
                pause
            }
            "2" { 
                Clear-Host
                Show-Status
                pause
            }
            "3" { 
                Clear-Host
                Show-Logs
                pause
            }
            "4" { 
                Clear-Host
                Show-Help
                pause
            }
            "0" { 
                Clear-Host
                Write-Title "退出程序"
                
                Write-Host "清理选项：" -ForegroundColor Yellow
                Write-Host ""
                Write-Host "1. 停止容器但保留镜像（推荐，默认）" -ForegroundColor Cyan
                Write-Host "2. 停止容器并删除所有镜像（完全清理）" -ForegroundColor Cyan
                Write-Host "3. 仅退出，保持容器运行" -ForegroundColor Cyan
                Write-Host ""
                $cleanChoice = Read-Host "请选择 [1-3，直接回车默认选1]"
                
                # 空格、空字符串或未输入时默认选择1
                if ([string]::IsNullOrWhiteSpace($cleanChoice)) {
                    $cleanChoice = "1"
                }
                
                switch ($cleanChoice.Trim()) {
                    "1" {
                        Write-Host ""
                        Write-Host "正在停止并删除容器..." -ForegroundColor Yellow
                        docker stop apple-music-wrapper 2>&1 | Out-Null
                        docker rm apple-music-wrapper 2>&1 | Out-Null
                        Write-Success "容器已清理"
                        Write-Info "镜像已保留，下次启动更快"
                    }
                    "2" {
                        Write-Host ""
                        Write-Host "正在清理所有容器、镜像和构建缓存..." -ForegroundColor Yellow
                        
                        # 停止并删除容器
                        Write-Host "  停止容器..." -ForegroundColor DarkGray
                        docker stop apple-music-wrapper 2>&1 | Out-Null
                        docker rm apple-music-wrapper 2>&1 | Out-Null
                        
                        # 删除镜像
                        Write-Host "  删除镜像..." -ForegroundColor DarkGray
                        docker rmi apple-music-wrapper 2>&1 | Out-Null
                        docker rmi apple-music-downloader 2>&1 | Out-Null
                        
                        # 清理构建缓存
                        Write-Host "  清理构建缓存..." -ForegroundColor DarkGray
                        docker builder prune -f 2>&1 | Out-Null
                        
                        Write-Success "所有容器、镜像和构建缓存已清理"
                        Write-Info "下次使用需要重新构建镜像"
                    }
                    "3" {
                        Write-Info "保持容器运行状态"
                    }
                    default {
                        Write-Info "未进行清理"
                    }
                }
                
                Write-Host ""
                Write-Host "程序已退出" -ForegroundColor Green
                Write-Host ""
                exit 0
            }
            default { 
                Write-Warning "无效的选择，请重新选择"
                Start-Sleep -Seconds 1
            }
        }
    }
}

# 主逻辑
if (-not $Action) {
    # 无参数时显示交互菜单
    Show-Menu
} else {
    # 根据参数执行对应操作
    switch ($Action.ToLower()) {
        "start" { 
            Start-Services
            pause
        }
        "stop" { 
            Stop-Services
            pause
        }
        "download" { 
            Start-Download -Url $Url -Song:$Song -Atmos:$Atmos -Aac:$Aac -Select:$Select -ShowDebug:$ShowDebug -AllAlbum:$AllAlbum
            pause
        }
        "status" { 
            Show-Status
            pause
        }
        "logs" { 
            Show-Logs
            pause
        }
        "clean" { 
            Clear-DockerResources
            pause
        }
        "help" { 
            Show-Help
            pause
        }
        default { 
            Write-Error "未知命令: $Action"
            Write-Host ""
            Show-Help
            pause
        }
    }
}

