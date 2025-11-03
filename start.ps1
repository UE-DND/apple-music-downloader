# Downloader Start Script

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# 
# 全局UI配置
$script:UI_BOX_WIDTH = 58  # 统一的边框宽度
#
# 使用示例：
#
# 1. 绘制标准框：
#    Draw-Box -Title "标题" -Content @("行1", "行2") -TitleColor Cyan -ContentColor White
#
# 2. 绘制双线框（用于重要提示）：
#    Draw-DoubleBox -Text "成功消息" -Color Green
#
# 3. 绘制菜单：
#    $items = @(
#        @{num="1"; text="选项1"; color="Cyan"; bg="DarkCyan"},
#        @{num="2"; text="选项2"; color="Red"; bg="DarkRed"}
#    )
#    Draw-Menu -Title "请选择：" -Items $items
#
# 4. 绘制步骤进度：
#    Draw-Step -StepNum "1/5" -Text "步骤描述"
#
# 5. 绘制信息框（单行）：
#    Draw-InfoBox -Text "提示信息" -Color Yellow
#
# 6. 绘制成功框：
#    Draw-SuccessBox -Title "操作成功" -Lines @("详情1", "详情2")
#
# 7. 绘制错误框：
#    Draw-ErrorBox -Text "错误信息"
#
# ============================================================================

# 计算字符串实际显示宽度（中文字符算2，ASCII算1）
function Get-DisplayWidth {
    param([string]$text)
    $width = 0
    foreach ($char in $text.ToCharArray()) {
        # 中文字符范围及其他全角字符
        if ($char -match '[\u4E00-\u9FFF\u3000-\u303F\uFF00-\uFFEF\u2000-\u206F]') {
            $width += 2
        } else {
            $width += 1
        }
    }
    return $width
}

# 填充字符串到指定显示宽度
function Format-FixedWidth {
    param(
        [string]$text,
        [int]$targetWidth,
        [string]$padChar = " "
    )
    $currentWidth = Get-DisplayWidth $text
    $paddingNeeded = $targetWidth - $currentWidth
    if ($paddingNeeded -gt 0) {
        return $text + ($padChar * $paddingNeeded)
    }
    return $text
}

# 绘制单线框
function Draw-Box {
    param(
        [string]$Title,
        [string[]]$Content,
        [int]$Width = $script:UI_BOX_WIDTH,
        [ConsoleColor]$TitleColor = 'Yellow',
        [ConsoleColor]$ContentColor = 'White',
        [ConsoleColor]$BorderColor = 'DarkGray'
    )
    
    $textWidth = $Width - 4
    
    # 顶部边框
    Write-Host ("┌" + ("─" * $Width) + "┐") -ForegroundColor $BorderColor
    
    # 标题
    if ($Title) {
        $paddedTitle = Format-FixedWidth $Title $textWidth
        Write-Host "│  " -NoNewline -ForegroundColor $BorderColor
        Write-Host $paddedTitle -NoNewline -ForegroundColor $TitleColor
        Write-Host "  │" -ForegroundColor $BorderColor
        
        if ($Content.Count -gt 0) {
            Write-Host ("├" + ("─" * $Width) + "┤") -ForegroundColor $BorderColor
        }
    }
    
    # 内容
    foreach ($line in $Content) {
        if ($line -eq "") {
            Write-Host ("│" + (" " * $Width) + "│") -ForegroundColor $BorderColor
        } else {
            $paddedLine = Format-FixedWidth $line $textWidth
            Write-Host "│  " -NoNewline -ForegroundColor $BorderColor
            Write-Host $paddedLine -NoNewline -ForegroundColor $ContentColor
            Write-Host "  │" -ForegroundColor $BorderColor
        }
    }
    
    # 底部边框
    Write-Host ("└" + ("─" * $Width) + "┘") -ForegroundColor $BorderColor
}

# 绘制双线框
function Draw-DoubleBox {
    param(
        [string]$Text,
        [int]$Width = $script:UI_BOX_WIDTH,
        [ConsoleColor]$Color = 'Green'
    )
    
    $textWidth = $Width - 4
    
    Write-Host ("╔" + ("═" * $Width) + "╗") -ForegroundColor $Color
    
    $paddedText = Format-FixedWidth "  $Text" $textWidth
    Write-Host ("║  " + $paddedText + "  ║") -ForegroundColor $Color
    
    Write-Host ("╚" + ("═" * $Width) + "╝") -ForegroundColor $Color
}

# 绘制菜单
function Draw-Menu {
    param(
        [string]$Title,
        [array]$Items,  # @{num="1"; text="文本"; color="Cyan"; bg="DarkCyan"}
        [int]$Width = $script:UI_BOX_WIDTH,
        [int]$SelectedIndex = -1
    )
    
    $titleWidth = $Width - 4
    
    Write-Host ("┌" + ("─" * $Width) + "┐") -ForegroundColor DarkGray
    
    # 标题
    $paddedTitle = Format-FixedWidth $Title $titleWidth
    Write-Host "│  " -NoNewline -ForegroundColor DarkGray
    Write-Host $paddedTitle -NoNewline -ForegroundColor Yellow
    Write-Host "  │" -ForegroundColor DarkGray
    
    Write-Host ("├" + ("─" * $Width) + "┤") -ForegroundColor DarkGray
    Write-Host ("│" + (" " * $Width) + "│") -ForegroundColor DarkGray
    
    # 菜单项
    $itemWidth = $Width - 4  # 内容区宽度
    for ($i = 0; $i -lt $Items.Count; $i++) {
        $item = $Items[$i]
        $numStr = $item.num.ToString()
        
        if ($SelectedIndex -eq $i) {
            # 高亮选中项 - 整行反色
            $textContent = $numStr + " " + $item.text
            $paddedContent = Format-FixedWidth $textContent $itemWidth
            
            Write-Host "│  " -NoNewline -ForegroundColor DarkGray
            Write-Host $paddedContent -NoNewline -ForegroundColor Black -BackgroundColor White
            Write-Host "  │" -ForegroundColor DarkGray
        } else {
            # 普通项 - 带颜色数字标签
            Write-Host "│  " -NoNewline -ForegroundColor DarkGray
            Write-Host $numStr -NoNewline -ForegroundColor White -BackgroundColor $item.bg
            Write-Host " " -NoNewline -ForegroundColor DarkGray
            
            # 计算文本宽度：总宽度 - num(1) - 空格(1)
            $textWidth = $itemWidth - 2
            $paddedText = Format-FixedWidth $item.text $textWidth
            Write-Host $paddedText -NoNewline -ForegroundColor $item.color
            Write-Host "  │" -ForegroundColor DarkGray
        }
    }
    
    Write-Host ("│" + (" " * $Width) + "│") -ForegroundColor DarkGray
    Write-Host ("└" + ("─" * $Width) + "┘") -ForegroundColor DarkGray
}

# 绘制步骤进度框
function Draw-Step {
    param(
        [string]$StepNum,  # "1/5"
        [string]$Text,
        [int]$Width = $script:UI_BOX_WIDTH
    )
    
    $textWidth = $Width - 4
    $lineWidth = $Width - 10
    
    Write-Host "┌─ " -NoNewline -ForegroundColor DarkGray
    Write-Host "步骤 $StepNum" -NoNewline -ForegroundColor White -BackgroundColor DarkBlue
    Write-Host (" " + ("─" * $lineWidth) + "┐") -ForegroundColor DarkGray
    
    $paddedText = Format-FixedWidth $Text $textWidth
    Write-Host ("│ " + $paddedText + " │") -ForegroundColor Green
    
    Write-Host ("└" + ("─" * $Width) + "┘") -ForegroundColor DarkGray
}

# 绘制信息框（单行）
function Draw-InfoBox {
    param(
        [string]$Text,
        [int]$Width = $script:UI_BOX_WIDTH,
        [ConsoleColor]$Color = 'Green'
    )
    
    $textWidth = $Width - 4
    
    Write-Host ("┌" + ("─" * $Width) + "┐") -ForegroundColor $Color
    
    $paddedText = Format-FixedWidth "  $Text" $textWidth
    Write-Host "│  " -NoNewline -ForegroundColor $Color
    Write-Host $paddedText -NoNewline -ForegroundColor $Color
    Write-Host "  │" -ForegroundColor $Color
    
    Write-Host ("└" + ("─" * $Width) + "┘") -ForegroundColor $Color
}

# 绘制成功框
function Draw-SuccessBox {
    param(
        [string]$Title,
        [string[]]$Lines,
        [int]$Width = $script:UI_BOX_WIDTH
    )
    
    $textWidth = $Width - 4
    
    Write-Host ("╔" + ("═" * $Width) + "╗") -ForegroundColor Green
    
    $paddedTitle = Format-FixedWidth "  $Title" $textWidth
    Write-Host ("║  " + $paddedTitle + "  ║") -ForegroundColor Green
    
    if ($Lines.Count -gt 0) {
        Write-Host ("╠" + ("═" * $Width) + "╣") -ForegroundColor DarkGray
        
        foreach ($line in $Lines) {
            $paddedLine = Format-FixedWidth "  $line" $textWidth
            Write-Host ("║  " + $paddedLine + "  ║") -ForegroundColor Cyan
        }
    }
    
    Write-Host ("╚" + ("═" * $Width) + "╝") -ForegroundColor Green
}

# 绘制错误框
function Draw-ErrorBox {
    param(
        [string]$Text,
        [int]$Width = $script:UI_BOX_WIDTH
    )
    
    $textWidth = $Width - 4
    
    Write-Host ("╔" + ("═" * $Width) + "╗") -ForegroundColor Red
    
    $paddedText = Format-FixedWidth "  $Text" $textWidth
    Write-Host ("║  " + $paddedText + "  ║") -ForegroundColor Red
    
    Write-Host ("╚" + ("═" * $Width) + "╝") -ForegroundColor Red
}

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
    $boxWidth = $script:UI_BOX_WIDTH
    $innerWidth = $boxWidth - 4  # 减去 "║  " 和 "  ║"
    
    Write-Host ""
    Write-Host ("╔" + ("═" * $boxWidth) + "╗") -ForegroundColor Cyan
    
    $paddedText = Format-FixedWidth "  $text" $innerWidth
    Write-Host ("║  " + $paddedText + "  ║") -ForegroundColor Cyan
    
    Write-Host ("╚" + ("═" * $boxWidth) + "╝") -ForegroundColor Cyan
    Write-Host ""
}

function Write-Success($text) {
    Write-Host "[" -NoNewline -ForegroundColor DarkGray
    Write-Host "✓" -NoNewline -ForegroundColor Green
    Write-Host "] " -NoNewline -ForegroundColor DarkGray
    Write-Host "$text" -ForegroundColor Green
}

function Write-Error($text) {
    Write-Host "[" -NoNewline -ForegroundColor DarkGray
    Write-Host "✗" -NoNewline -ForegroundColor Red
    Write-Host "] " -NoNewline -ForegroundColor DarkGray
    Write-Host "$text" -ForegroundColor Red
}

function Write-Warning($text) {
    Write-Host "[" -NoNewline -ForegroundColor DarkGray
    Write-Host "!" -NoNewline -ForegroundColor Yellow
    Write-Host "] " -NoNewline -ForegroundColor DarkGray
    Write-Host "$text" -ForegroundColor Yellow
}

function Write-Info($text) {
    Write-Host "[" -NoNewline -ForegroundColor DarkGray
    Write-Host "i" -NoNewline -ForegroundColor Cyan
    Write-Host "] " -NoNewline -ForegroundColor DarkGray
    Write-Host "$text" -ForegroundColor Cyan
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
    Draw-Step -StepNum "1/5" -Text "检查 Docker 状态..."
    if (-not (Test-Docker)) {
        pause
        return
    }
    Write-Host ""
    
    # 检查镜像
    Draw-Step -StepNum "2/5" -Text "检查 Docker 镜像..."
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
    Draw-Step -StepNum "3/5" -Text "清理旧容器..."
    $oldContainer = docker ps -a -q --filter "name=apple-music-wrapper" 2>$null
    if ($oldContainer) {
        docker rm -f apple-music-wrapper 2>$null | Out-Null
        Write-Success "已清理旧容器"
    } else {
        Write-Success "无需清理"
    }
    Write-Host ""
    
    # 配置凭证
    Draw-Step -StepNum "4/5" -Text "配置登录凭证..."
    $credentialPath = "wrapper\rootfs\data\data\com.apple.android.music"
    $hasCredentials = Test-Path "$credentialPath\*"
    $needInteractiveLogin = $false
    
    if ($hasCredentials) {
        Write-Host "[" -NoNewline -ForegroundColor DarkGray
        Write-Host "!" -NoNewline -ForegroundColor Yellow
        Write-Host "] " -NoNewline -ForegroundColor DarkGray
        Write-Host "检测到本地凭证" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "► " -NoNewline -ForegroundColor Green
        $useExisting = Read-Host "是否使用本地凭证? (Y/n)"
        
        if ($useExisting -eq "" -or $useExisting -eq "Y" -or $useExisting -eq "y") {
            $loginArgs = "-H 0.0.0.0"
            Write-Success "使用本地凭证登录"
        } else {
            Write-Host "[" -NoNewline -ForegroundColor DarkGray
            Write-Host "!" -NoNewline -ForegroundColor Yellow
            Write-Host "] " -NoNewline -ForegroundColor DarkGray
            Write-Host "清除旧凭证..." -ForegroundColor Yellow
            Remove-Item -Path "$credentialPath\*" -Recurse -Force -ErrorAction SilentlyContinue
            
        Write-Host ""
        Draw-Box -Title "🔐 登录 Apple ID" -Content @("注意：Apple ID 需要拥有 Apple Music 订阅") -TitleColor Cyan -ContentColor Yellow
        Write-Host ""
            Write-Host "► " -NoNewline -ForegroundColor Green
            $email = Read-Host "Apple ID"
            Write-Host "► " -NoNewline -ForegroundColor Green
            $password = Read-Host "密码" -AsSecureString
            $passwordPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))
            
            $loginArgs = "-L ${email}:${passwordPlain} -H 0.0.0.0"
            $needInteractiveLogin = $true
            Write-Success "凭证配置完成（将使用交互模式登录）"
        }
    } else {
        Write-Host ""
        Draw-Box -Title "🔐 首次使用须登录 Apple ID" -Content @("注意：Apple ID 需要拥有 Apple Music 订阅") -TitleColor Cyan -ContentColor Yellow
        Write-Host ""
        Write-Host "► " -NoNewline -ForegroundColor Green
        $email = Read-Host "Apple ID"
        Write-Host "► " -NoNewline -ForegroundColor Green
        $password = Read-Host "密码" -AsSecureString
        $passwordPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))
        
        $loginArgs = "-L ${email}:${passwordPlain} -H 0.0.0.0"
        $needInteractiveLogin = $true
        Write-Success "凭证配置完成（将使用交互模式登录）"
    }
    Write-Host ""
    
    # 启动容器
    Draw-Step -StepNum "5/5" -Text "启动 Wrapper 容器..."
    $wrapperPath = Join-Path (Get-Location) "wrapper"
    
    if ($needInteractiveLogin) {
        Write-Host ""
        Write-Title "使用交互模式登录"
        $notes = @(
            "1️⃣  如果账号开启了双因素认证（2FA），验证码会发送",
            "    到你的 Apple 设备",
            "",
            "2️⃣  请在下方提示时输入收到的验证码",
            "",
            "3️⃣  若长时间未收到验证码，尝试输入最后一次收到的",
            "    验证码",
            "",
            "4️⃣  登录成功后容器会自动切换到后台运行"
        )
        Draw-Box -Title "⚠ 注意事项" -Content $notes -TitleColor Yellow -ContentColor Yellow -BorderColor Yellow -Width $script:UI_BOX_WIDTH
        Write-Host ""
        $tips = @(
            "Apple 验证码通常在几秒内送达，如超过1分钟未收到，",
            "可能是短时间内请求过多，建议等待15-30分钟后重试"
        )
        Draw-Box -Title "💡 提示" -Content $tips -TitleColor Cyan -ContentColor Cyan -BorderColor Cyan -Width $script:UI_BOX_WIDTH
        Write-Host ""
        Draw-InfoBox -Text "按任意键继续..." -Color Gray
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        Write-Host ""
        
        Draw-InfoBox -Text "🚀 正在启动交互式登录..." -Color Green
        Write-Host ""
        
        # 启动监控脚本
        $monitorScript = {
            param($containerName)
            Start-Sleep -Seconds 5
            
            $maxWaitTime = 300
            $startTime = Get-Date
            
            while (((Get-Date) - $startTime).TotalSeconds -lt $maxWaitTime) {
                try {
                    $logs = docker logs $containerName 2>&1 | Out-String
                    
                    # 检查是否已经开始监听端口（表示登录成功）
                    if ($logs -match "listening.*10020" -and $logs -match "listening.*20020") {
                        # 等待几秒确保凭证已保存
                        Start-Sleep -Seconds 3
                        # 停止容器
                        docker stop $containerName 2>&1 | Out-Null
                        break
                    }
                } catch {
                    # 容器可能已停止或还未启动
                }
                
                Start-Sleep -Seconds 2
            }
        }
        
        # 在后台启动监控任务
        $monitorJob = Start-Job -ScriptBlock $monitorScript -ArgumentList "apple-music-wrapper"
        
        # 以交互模式启动容器（阻塞直到容器停止）
        docker run --rm -it --name apple-music-wrapper `
            -v "${wrapperPath}\rootfs\data:/app/rootfs/data" `
            -p 10020:10020 `
            -p 20020:20020 `
            -e args="$loginArgs" `
            apple-music-wrapper
        
        # 清理监控任务
        Stop-Job $monitorJob -ErrorAction SilentlyContinue 2>&1 | Out-Null
        Remove-Job $monitorJob -Force -ErrorAction SilentlyContinue 2>&1 | Out-Null
        
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
        Draw-Box -Title "" -Content @(
            "🔓 解密端口: 127.0.0.1:10020",
            "📺 M3U8端口: 127.0.0.1:20020"
        ) -ContentColor Green
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
    
    Write-Title "Apple Music Downloader"
    
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
        Draw-InfoBox -Text "🔗 请输入要下载的链接" -Color Yellow
        Write-Host ""
        Write-Host "► " -NoNewline -ForegroundColor Green
        $Url = Read-Host "链接"
        
        if (-not $Url) {
            Write-Error "未提供链接"
            pause
            return
        }
        
        Write-Host ""
        $downloadOptions = @(
            @{num="1"; text="🎵 单曲"; color="Cyan"; bg="DarkCyan"},
            @{num="2"; text="💿 完整专辑/播放列表"; color="Cyan"; bg="DarkCyan"},
            @{num="3"; text="✅选择性下载"; color="Cyan"; bg="DarkCyan"},
            @{num="4"; text="🎧 杜比全景声"; color="Magenta"; bg="DarkMagenta"},
            @{num="5"; text="🎼 AAC 格式"; color="Cyan"; bg="DarkCyan"},
            @{num="6"; text="ℹ️  查看音质信息"; color="Blue"; bg="DarkBlue"}
        )
        
        Draw-Menu -Title "📝 选择下载类型：" -Items $downloadOptions
        Write-Host ""
        Write-Host "► " -NoNewline -ForegroundColor Green
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
        Draw-SuccessBox -Title "✅ 下载完成！" -Lines @("📁 文件保存在: AM-DL downloads\")
        Write-Host ""
    } else {
        Draw-ErrorBox -Text "❌ 下载过程中出现错误"
        Write-Host ""
    }
    Write-Host ""
}

# 查看状态
function Show-Status {
    Write-Title "服务状态"
    
    # 检查容器状态
    $containerStatus = docker ps --filter "name=apple-music-wrapper" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    
    if ($containerStatus -match "apple-music-wrapper") {
        Draw-InfoBox -Text "✅ Wrapper 服务运行中" -Color Green
        Write-Host ""
        docker ps --filter "name=apple-music-wrapper" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
        Write-Host ""
        
        # 检查端口监听
        $logs = docker logs apple-music-wrapper 2>&1 | Out-String
        if ($logs -match "listening.*10020" -and $logs -match "listening.*20020") {
            Draw-Box -Title "✅ 端口监听正常" -Content @(
                "🔓 解密端口: 127.0.0.1:10020",
                "📺 M3U8端口: 127.0.0.1:20020"
            ) -TitleColor Green -ContentColor Cyan
        } else {
            Write-Warning "端口监听状态未知，请查看日志"
        }
    } else {
        Draw-Box -Title "⚠ Wrapper 服务未运行" -Content @(
            "使用以下命令启动：",
            ".\start.ps1 download [链接]"
        ) -TitleColor Yellow -ContentColor White -BorderColor Yellow
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
    
    Draw-InfoBox -Text "📋 显示最近 50 行日志" -Color Cyan
    Write-Host ""
    docker logs --tail 50 apple-music-wrapper 2>&1
    Write-Host ""
    
    Draw-Box -Title "💡 提示" -Content @(
        "使用以下命令查看实时日志：",
        "docker logs -f apple-music-wrapper"
    ) -TitleColor Cyan -ContentColor White
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
    $menuItems = @(
        @{num="1"; text="下载音乐"; color="Cyan"; bg="DarkCyan"; action="download"},
        @{num="2"; text="查看服务状态"; color="Cyan"; bg="DarkCyan"; action="status"},
        @{num="3"; text="查看日志"; color="Cyan"; bg="DarkCyan"; action="logs"},
        @{num="4"; text="帮助"; color="Cyan"; bg="DarkCyan"; action="help"},
        @{num="0"; text="退出"; color="Red"; bg="DarkRed"; action="exit"}
    )

    $selected = 0

    while ($true) {
        Clear-Host
        Write-Title "Apple Music Downloader"

        Draw-Menu -Title "请选择操作：" -Items $menuItems -SelectedIndex $selected
        Write-Host ""
        Write-Host "↑↓ 选择，Enter 确认，Esc 退出" -ForegroundColor DarkGray

        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        
        # 使用 VirtualKeyCode 进行更可靠的按键检测
        $keyCode = $key.VirtualKeyCode
        
        # 上箭头: 38, 下箭头: 40, Enter: 13, Esc: 27
        if ($keyCode -eq 38) {
            # 上箭头
            if ($menuItems.Count -eq 0) { continue }
            $selected = if ($selected -le 0) { $menuItems.Count - 1 } else { $selected - 1 }
            continue
        }
        elseif ($keyCode -eq 40) {
            # 下箭头
            if ($menuItems.Count -eq 0) { continue }
            $selected = if ($selected -ge $menuItems.Count - 1) { 0 } else { $selected + 1 }
            continue
        }
        elseif ($keyCode -eq 27) {
            # Esc
            return
        }
        elseif ($keyCode -eq 13) {
            # Enter
            if ($menuItems.Count -eq 0) { continue }
            $action = $menuItems[$selected].action

            switch ($action) {
                "download" {
                    Clear-Host
                    Start-Download -Url $null
                    pause
                }
                "status" {
                    Clear-Host
                    Show-Status
                    pause
                }
                "logs" {
                    Clear-Host
                    Show-Logs
                    pause
                }
                "help" {
                    Clear-Host
                    Show-Help
                    pause
                }
                "exit" {
                    $cleanOptions = @(
                        @{num="1"; text="停止容器但保留镜像（推荐，默认）"; color="Cyan"; bg="DarkGreen"; action="stop"},
                        @{num="2"; text="停止容器并删除所有镜像（完全清理）"; color="Cyan"; bg="DarkYellow"; action="clean"},
                        @{num="3"; text="仅退出，保持容器运行"; color="Cyan"; bg="DarkCyan"; action="keep"}
                    )
                    
                    $cleanSelected = 0
                    
                    while ($true) {
                        Clear-Host
                        Write-Title "退出程序"
                        
                        Draw-Menu -Title "清理选项：" -Items $cleanOptions -SelectedIndex $cleanSelected
                        Write-Host ""
                        Write-Host "↑↓ 选择，Enter 确认" -ForegroundColor DarkGray
                        
                        $cleanKey = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                        $cleanKeyCode = $cleanKey.VirtualKeyCode
                        
                        if ($cleanKeyCode -eq 38) {
                            # 上箭头
                            $cleanSelected = if ($cleanSelected -le 0) { $cleanOptions.Count - 1 } else { $cleanSelected - 1 }
                        }
                        elseif ($cleanKeyCode -eq 40) {
                            # 下箭头
                            $cleanSelected = if ($cleanSelected -ge $cleanOptions.Count - 1) { 0 } else { $cleanSelected + 1 }
                        }
                        elseif ($cleanKeyCode -eq 13) {
                            # Enter - 执行选中的操作
                            $cleanAction = $cleanOptions[$cleanSelected].action
                            break
                        }
                    }
                    
                    # 执行清理操作
                    Clear-Host
                    Write-Title "退出程序"
                    Write-Host ""
                    
                    switch ($cleanAction) {
                        "stop" {
                            Write-Host "正在停止并删除容器..." -ForegroundColor Yellow
                            docker stop apple-music-wrapper 2>&1 | Out-Null
                            docker rm apple-music-wrapper 2>&1 | Out-Null
                            Write-Success "容器已清理"
                            Write-Info "镜像已保留，下次启动更快"
                        }
                        "clean" {
                            Write-Host "正在清理所有容器、镜像和构建缓存..." -ForegroundColor Yellow

                            Write-Host "  停止容器..." -ForegroundColor DarkGray
                            docker stop apple-music-wrapper 2>&1 | Out-Null
                            docker rm apple-music-wrapper 2>&1 | Out-Null

                            Write-Host "  删除镜像..." -ForegroundColor DarkGray
                            docker rmi apple-music-wrapper 2>&1 | Out-Null
                            docker rmi apple-music-downloader 2>&1 | Out-Null

                            Write-Host "  清理构建缓存..." -ForegroundColor DarkGray
                            docker builder prune -f 2>&1 | Out-Null

                            Write-Success "所有容器、镜像和构建缓存已清理"
                            Write-Info "下次使用需要重新构建镜像"
                        }
                        "keep" {
                            Write-Info "保持容器运行状态"
                        }
                    }

                    Write-Host ""
                    Draw-DoubleBox -Text "程序已退出！" -Color Green
                    Write-Host ""
                    exit 0
                }
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

