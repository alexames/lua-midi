Set-Location $PSScriptRoot
$tests = Get-ChildItem tests\*.lua
$failed = 0
foreach ($f in $tests) {
  Write-Host "=== $($f.Name) ==="
  & .\lua.bat $f.FullName
  if ($LASTEXITCODE -ne 0) { $failed++ }
}
if ($failed -gt 0) {
  Write-Host "`n$failed test file(s) FAILED" -ForegroundColor Red
  exit 1
} else {
  Write-Host "`nAll test files passed" -ForegroundColor Green
}
