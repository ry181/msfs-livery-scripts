# 定義塗裝資料夾路徑
# $folderPath = "G:\addon-msfs2024\iniBuilds\我的塗裝\EVA_A350_Travel_Fun\inibuilds-aircraft-a350-1000-EVA-Travel-Fun"

# 檢查是否有提供參數，否則使用當前目錄
$folderPath = if ($args.Count -gt 0) { $args[0] } else { Get-Location | Select-Object -ExpandProperty Path }

# 將目標路徑轉換為完整路徑
try {
    # 移除 $folderPath 結尾的反斜線
    if ($folderPath.EndsWith("\")) {
        $folderPath = $folderPath.TrimEnd("\")
    }
    $folderPath = Resolve-Path -Path $folderPath | Select-Object -ExpandProperty Path
} catch {
    Write-Host "提供的路徑無法解析：$folderPath"
    exit
}

# 顯示目標目錄
Write-Host "目標目錄為：$folderPath"

# 定義 layout.json 文件的輸出路徑
$outputPath = "$folderPath\layout.json"

# 遍歷所有可能層級中的 texture 資料夾內的 .KTX2 檔案
Get-ChildItem -Path $folderPath -Recurse -File -Filter "*.ktx2" | ForEach-Object {
    $ktx2FilePath = $_.FullName
    $ktx2JsonPath = "$ktx2FilePath.json"
    $fileDate = $_.LastWriteTimeUtc.ToFileTimeUtc()

    # 定義 .KTX2.json 的內容
    $ktx2JsonContent = @{
        "Version" = 2
        "SourceFileDate" = $fileDate
        "Flags" = @("FL_BITMAP_COMPRESSION", "FL_BITMAP_MIPMAP", "FL_BITMAP_QUALITY_HIGH")
        "HasTransp" = $true
    } | ConvertTo-Json -Depth 10

    # 寫入 .KTX2.json 文件
    Set-Content -Path $ktx2JsonPath -Value $ktx2JsonContent -Encoding UTF8

    Write-Host "生成 .KTX2.json: $ktx2JsonPath"
}

# 遍歷所有可能層級中的 texture 資料夾內的 .DDS 檔案
Get-ChildItem -Path $folderPath -Recurse -File -Filter "*.DDS" | ForEach-Object {
    $ddsFilePath = $_.FullName
    $ddsJsonPath = "$ddsFilePath.json"
    $fileDate = $_.LastWriteTimeUtc.ToFileTimeUtc()

    # 定義 .DDS.json 的內容
    $ddsJsonContent = @{
        "Version" = 2
        "SourceFileDate" = $fileDate
        "Flags" = @("FL_BITMAP_COMPRESSION", "FL_BITMAP_MIPMAP", "FL_BITMAP_QUALITY_HIGH")
        "HasTransp" = $true
    } | ConvertTo-Json -Depth 10

    # 寫入 .DDS.json 文件
    Set-Content -Path $ddsJsonPath -Value $ddsJsonContent -Encoding UTF8

    Write-Host "生成 .DDS.json: $ddsJsonPath"
}


# 初始化文件列表
$fileList = @()

# 遍歷資料夾中的所有檔案，過濾掉目錄和 layout.json/manifest.json
Get-ChildItem -Path $folderPath -Recurse -File | Where-Object {
    $_.Name -notmatch "^(layout\.json|manifest\.json)$"
} | ForEach-Object {
    $filePath = $_.FullName
    $relativePath = $filePath.Substring($folderPath.Length + 1).Replace("\", "/")
    $fileSize = $_.Length
    $fileDate = $_.LastWriteTimeUtc.ToFileTimeUtc()

    # 添加檔案到文件列表
    $fileList += @{
        "path" = $relativePath
        "size" = $fileSize
        "date" = $fileDate
    }
}

# 生成 layout.json 的 JSON 字串
$json = @{
    "content" = $fileList
} | ConvertTo-Json -Depth 10

# 將 JSON 輸出到 layout.json 文件
Set-Content -Path $outputPath -Value $json -Encoding UTF8

Write-Host "layout.json 已成功生成於 $outputPath，並排除了 layout.json 和 manifest.json"
