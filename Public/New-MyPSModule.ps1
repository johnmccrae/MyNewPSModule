<#
.SYNOPSIS
A module used to create new PS Modules with.

.DESCRIPTION
This module uses Plaster to create all the essential parts of a PowerShell Module

.EXAMPLE
New-MyPSModule -MyNewModuleName "MyFabModule" -

.DEPENDENCIES
The following modules must be installed or this won't work at all
Plaster
InvokeBuild
PSGraph
PlatyPS
Pester
PSDepend


.NOTES

    # reference - https://kevinmarquette.github.io/2017-05-12-Powershell-Plaster-adventures-in/
    # reference - https://mikefrobbins.com/2018/02/15/using-plaster-to-create-a-powershell-script-module-template/
    # reference - Auf Deutsch! https://mycloudrevolution.com/2017/06/01/my-custom-plaster-template/
    # reference - https://kevinmarquette.github.io/2017-01-21-powershell-module-continious-delivery-pipeline/?utm_source=blog&utm_medium=blog&utm_content=titlelink
    # reference - https://github.com/PowerShell/platyPS
    # reference - https://overpoweredshell.com/Working-with-Plaster/#using-token-replacement

    General notes

#>

function New-MyPSModule {

    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    param (
        [Parameter(Mandatory = $true)]
        [string]$MyNewModuleName,

        [Parameter(Mandatory = $true)]
        [ValidateSet("Basic.xml", "Extended.xml", "Advanced.xml")]
        [string]$BaseManifest,

        [Parameter(Mandatory = $false)]
        [string]$moduleroot = ""
    )

    begin {
        $ErrorActionPreference = 'Stop'
    }

    process {

        $templateroot = $MyInvocation.MyCommand.Module.ModuleBase

        Set-Location $templateroot

        #$templateroot = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath('./')

        # check for old plastermanifest and delete it.
        if (Test-Path $templateroot\PlasterManifest.xml -PathType Leaf)
            {
                Remove-Item -Path PlasterManifest.xml
            }

        $plasterdoc = Get-ChildItem $templateroot -Filter $basemanifest -Recurse | ForEach-Object { $_.FullName }

        Copy-Item -Path $plasterdoc "$templateroot\PlasterManifest.xml"

        if ($PSVersionTable.PSEdition -eq "Desktop") {

            if (!$moduleroot){
                $moduleroot = "c:\modules"
            }
            if (-not (Test-Path -path $moduleroot) ) {

                New-Item -Path "$moduleroot" -ItemType Directory
            }

            Set-Location $moduleroot

        }
        elseif ($PSVersionTable.PSEdition -eq "Core") {

            if (($isMACOS) -or ($isLinux)) {

                if (!$moduleroot) {
                    $moduleroot = "~/modules"
                }
                if (-not (Test-Path -path $moduleroot) ) {

                    New-Item -Path "$moduleroot" -ItemType Directory
                }

                Set-Location $moduleroot

            }
            else {

                if (!$moduleroot) {
                    $moduleroot = "c:\modules"
                }
                if (-not (Test-Path -path $moduleroot) ) {

                    New-Item -Path "$moduleroot" -ItemType Directory
                }

                Set-Location $moduleroot

            }
        }

        $PlasterParams = @{
            TemplatePath       = $templateroot #where the plaster manifest xml file lives
            Destination        = $moduleroot #where my new module is going to live
            ModuleName         = $MyNewModuleName
            #Description       = 'PowerShell Script Module Building Toolkit'
            #Version           = '1.0.0'
            ModuleAuthor       = 'John McCrae'
            #CompanyName       = 'Chef Software Inc'
            #FunctionFolders   = 'public', 'private'
            #Git               = 'Yes'
            GitHubUserName	   = 'johnmccrae'
            #GitHubRepo        = 'ModuleBuildTools'
            #Options           = ('License', 'Readme', 'GitIgnore', 'GitAttributes')
            PowerShellVersion  = '3.0' #minimum PS version
            # Apart from Templatepath and Destination, these parameters need to match what's in the <parameters> section of the manifest.
        }

        Invoke-Plaster @PlasterParams -Force -Verbose

        $MyNewModuleName = $MyNewModuleName -replace '.ps1', ''

        #region File contents
        #keep this formatted as is. the format is output to the file as is, including indentation
        $scriptCode = "function $MyNewModuleName {$([System.Environment]::NewLine)$([System.Environment]::NewLine)}"

        <#
        $testCode = '$here = Split-Path -Parent $MyInvocation.MyCommand.Path
        $sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace ''\.Tests\.'', ''.''
        . "$here\$sut"

        Describe "#name#" {
            It "does something useful" {
                $true | Should -Be $false
            }
        }' -replace "#name#", $MyNewModuleName
        #>
        #endregion

        $Path = "$moduleroot\$MyNewModuleName"

        if (Test-Path "$Path\public"){
            Create-File -Path "$Path\Public" -Name "$MyNewModuleName.ps1" -Content $scriptCode
        }
        else {
            Create-File -Path $Path -Name "$MyNewModuleName.ps1" -Content $scriptCode
        }

        <#
        if(Test-Path "$moduleroot\tests"){
            Create-File -Path "$moduleroot\tests" -Name "$MyNewModuleName.Tests.ps1" -Content $testCode
        }
        else{
            Create-File -Path $moduleroot -Name "$MyNewModuleName.Tests.ps1" -Content $testCode
        }
        #>

    }
    end{}
}
#Export-ModuleMember -Function new-myposmodule