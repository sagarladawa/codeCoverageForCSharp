
#########################################################
###   Please go through ReadmeFirst.md before usage   ###
#########################################################

# Change directory to the directory of this script
Set-Location $PSScriptRoot
# Check if TestCoverageReport folder exists, delete it if it does
if (Test-Path "TestCoverageReport") {
    Remove-Item "TestCoverageReport" -Recurse -Force
}



# Check if the Test Project has built successfully
if (-not (Test-Path "bin\x64\Debug\net5.0-windows\CSProj.Tests.dll")) {
    Write-Host "`n[ERR]: Test Project not yet built! Report generation aborted`n" -ForegroundColor Red
    exit
}



Write-Host "`n[START]: Build, Test, Collect!`n"
# Run tests and collect coverage using Coverlet and verify
# Be mindful of the Exclude property: It was used here as Microsoft.Xaml.Behaviors was getting included as Assembly in the coverage which we did not want
# You can exclude other assemblies as well to have focussed coverage report
dotnet test /p:CollectCoverage=true /p:CoverletOutputFormat=cobertura /p:Exclude="[Microsoft*]*" /p:CoverletOutput=TestCoverageReport\Coverage\coverage.xml
if (-not (Test-Path "TestCoverageReport\Coverage\coverage.xml")) {
    Write-Host "`n[ERR]: Coverlet could not collect cobertura test data i.e. coverage.xml! Report generation aborted`n" -ForegroundColor Red
    exit
}
Write-Host "`n[COMPLETE]: Build, Test, Collect!`n" -ForegroundColor Green



Write-Host "`n[START]: Generate TestCoverageReport!`n"
# Generate coverage report using ReportGenerator and verify
reportgenerator -reports:"TestCoverageReport\Coverage\coverage.xml" -targetdir:"TestCoverageReport\Coverage" -reporttypes:Html
if (-not (Test-Path "TestCoverageReport\Coverage\index.html")) {
    Write-Host "`n[ERR]: Coverlet could not create cobertura report i.e. index.html! Report generation aborted`n" -ForegroundColor Red
    exit
}
Write-Host "`n[COMPLETE]: Generate TestCoverageReport!`n" -ForegroundColor Green



# Dump results
Write-Host "[RESULT]:"
# Get the content of coverage.xml file
$xmlContent = Get-Content "TestCoverageReport\Coverage\coverage.xml"
# Load the XML content
$xml = [xml]$xmlContent
# Extract the attributes from the first line of the XML content
$coverageNode = $xml.SelectSingleNode("//coverage")
$lineRate = $coverageNode.GetAttribute("line-rate")
$branchRate = $coverageNode.GetAttribute("branch-rate")
$linesCovered = $coverageNode.GetAttribute("lines-covered")
$linesValid = $coverageNode.GetAttribute("lines-valid")
$branchesCovered = $coverageNode.GetAttribute("branches-covered")
$branchesValid = $coverageNode.GetAttribute("branches-valid")
# Calculate coverage percentage
$coveragePercentage = [math]::Round(($linesCovered / $linesValid) * 100, 2)
# Output the extracted attributes
Write-Host " % coverage: $coveragePercentage%"
Write-Host " lineRate: $lineRate"
Write-Host " branchRate: $branchRate"
Write-Host " linesCovered: $linesCovered"
Write-Host " linesValid: $linesValid"
Write-Host " branchesCovered: $branchesCovered"
Write-Host " branchesValid: $branchesValid"



# Create a shortcut to the coverage report
$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("$PSScriptRoot\TestCoverageReport\TestCoverageReport.html.lnk")
$Shortcut.TargetPath = "$PSScriptRoot\TestCoverageReport\Coverage\index.html"
$Shortcut.Save()
# Check if index.html exists in TestCoverageReport\Coverage folder
if (Test-Path "$PSScriptRoot\TestCoverageReport\TestCoverageReport.html.lnk") {
    Write-Host "`n[OK]: `"TestCoverageReport.html`" generated successfully in the TestCoverageReport\Coverage folder!`n" -ForegroundColor Green
    # Open the generated HTML report
    Start-Process "$PSScriptRoot\TestCoverageReport\TestCoverageReport.html.lnk"
} else {
    Write-Host "`n[ERR]: `"TestCoverageReport.html`" not created due to report generation failure.`n" -ForegroundColor Red
}
