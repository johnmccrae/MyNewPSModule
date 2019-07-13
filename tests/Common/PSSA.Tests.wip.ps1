# This runs all PSScriptAnalyzer rules as Pester tests to enable visibility when publishing test results
# Vars
$ScriptAnalyzerSettingsPath = Join-Path -Path $env:BHProjectPath -ChildPath 'Build\PSScriptAnalyzerSettings.psd1'

Describe 'Testing against PSSA rules' {
    Context 'PSSA Standard Rules' {
        $analysis = Invoke-ScriptAnalyzer -Path $env:BHPSModulePath -Recurse -Settings $ScriptAnalyzerSettingsPath
        $scriptAnalyzerRules = Get-ScriptAnalyzerRule

        forEach ($rule in $scriptAnalyzerRules) {
            It "Should pass $rule" {
                If ($analysis.RuleName -contains $rule) {
                    $analysis | Where-Object RuleName -EQ $rule -OutVariable 'failures' | Out-Default
                    $failures.Count | Should Be 0
                }
            }
        }
    }
}