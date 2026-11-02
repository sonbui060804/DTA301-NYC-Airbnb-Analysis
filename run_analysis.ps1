# Chạy từ gốc checkout bằng PowerShell 7: pwsh -File .\run_analysis.ps1
# Mặc định chỉ kiểm thử; dùng -Stage All khi muốn chạy lại toàn bộ phân tích.
param(
    [ValidateSet('Checks', 'All')]
    [string]$Stage = 'Checks',
    [string]$RscriptPath = ''
)

$ErrorActionPreference = 'Stop'
$airbnbProject = Join-Path $PSScriptRoot 'DTA301-NYC-Airbnb-Analysis'
if (-not (Test-Path -LiteralPath (Join-Path $airbnbProject 'code/analysis_helpers.R') -PathType Leaf)) {
    throw 'Không tìm thấy thư mục dự án có code/analysis_helpers.R.'
}

# Ưu tiên đường dẫn người dùng cung cấp, rồi PATH, cuối cùng tìm bản R đã cài.
if (-not $RscriptPath) {
    $airbnbCommand = Get-Command Rscript.exe -ErrorAction SilentlyContinue
    if ($airbnbCommand) {
        $RscriptPath = $airbnbCommand.Source
    } else {
        $airbnbInstallations = Get-ChildItem -LiteralPath (Join-Path $env:ProgramFiles 'R') -Directory -ErrorAction SilentlyContinue |
            Sort-Object Name -Descending
        foreach ($airbnbInstallation in $airbnbInstallations) {
            $airbnbCandidate = Join-Path $airbnbInstallation.FullName 'bin/x64/Rscript.exe'
            if (Test-Path -LiteralPath $airbnbCandidate -PathType Leaf) {
                $RscriptPath = $airbnbCandidate
                break
            }
        }
    }
}
if (-not $RscriptPath -or -not (Test-Path -LiteralPath $RscriptPath -PathType Leaf)) {
    throw 'Không tìm thấy Rscript.exe. Hãy truyền -RscriptPath với đường dẫn bản R đã cài.'
}

$airbnbScripts = @('tests/test_analysis.R')
if ($Stage -eq 'All') {
    $airbnbScripts += @(
        'code/01_Data_Cleaning/01_data_cleaning.R',
        'code/01_Data_Cleaning/01b_clean_reviews.R',
        'code/02_Feature_Engineering/prepare_airbnb_model.R',
        'code/03_EDA/03_EDA_Visualization.R',
        'code/04_Modeling/04_Modeling.R',
        'code/04_Modeling/04_Sentiment_Analysis.R'
    )
}

# Kiểm tra TẤT CẢ đường dẫn trước khi gọi R. Bản Rscript hiện tại có thể crash
# với 0xC0000005 khi file script không tồn tại, thay vì báo lỗi thiếu file bình thường.
foreach ($airbnbScript in $airbnbScripts) {
    $airbnbFullPath = Join-Path $airbnbProject $airbnbScript
    if (-not (Test-Path -LiteralPath $airbnbFullPath -PathType Leaf)) {
        throw "Không chạy R vì thiếu file: $airbnbFullPath"
    }
}

# Locale C.UTF-8 kế thừa từ môi trường Unix có thể không hợp lệ trên Windows.
# Chỉ dùng locale mặc định Windows cho tiến trình con; khôi phục môi trường sau khi chạy.
$airbnbSavedLocale = @{}
foreach ($airbnbName in @('LANG', 'LC_ALL', 'LC_CTYPE')) {
    $airbnbSavedLocale[$airbnbName] = [Environment]::GetEnvironmentVariable($airbnbName, 'Process')
    [Environment]::SetEnvironmentVariable($airbnbName, $null, 'Process')
}
Push-Location -LiteralPath $airbnbProject
try {
    foreach ($airbnbScript in $airbnbScripts) {
        Write-Host "Đang chạy: $airbnbScript"
        & $RscriptPath --vanilla (Join-Path $airbnbProject $airbnbScript)
        if ($LASTEXITCODE -ne 0) {
            throw "Bước $airbnbScript dừng với mã $LASTEXITCODE. Hãy kiểm tra thông báo phía trên."
        }
    }
} finally {
    Pop-Location
    foreach ($airbnbName in $airbnbSavedLocale.Keys) {
        [Environment]::SetEnvironmentVariable($airbnbName, $airbnbSavedLocale[$airbnbName], 'Process')
    }
}
