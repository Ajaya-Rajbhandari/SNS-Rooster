# add_logger_import.ps1
param(
  [string]$Root = "sns_rooster\lib"
)

Get-ChildItem $Root -Filter *.dart -Recurse | ForEach-Object {
  $file  = $_.FullName
  $text  = Get-Content $file
  if ($text -match '\blog\(' -and $text -notmatch 'package:sns_rooster/utils/logger.dart') {
    Write-Host "Adding logger import to $file"
    $firstImport = ($text | Select-String '^import ' | Select-Object -First 1).LineNumber
    if ($firstImport) {
      $before = $text[0..($firstImport - 1)]
      $after  = $text[$firstImport..($text.Length - 1)]
      $new    = $before + "import 'package:sns_rooster/utils/logger.dart';" + $after
      Set-Content -Path $file -Value $new -Encoding UTF8
    }
  }
}
