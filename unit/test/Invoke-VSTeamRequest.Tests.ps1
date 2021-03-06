Set-StrictMode -Version Latest

#region include
Import-Module SHiPS

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")

. "$here/../../Source/Private/common.ps1"
. "$here/../../Source/Classes/VSTeamVersions.ps1"
. "$here/../../Source/Classes/VSTeamLeaf.ps1"
. "$here/../../Source/Classes/VSTeamDirectory.ps1"
. "$here/../../Source/Classes/VSTeamProjectCache.ps1"
. "$here/../../Source/Classes/InvokeCompleter.ps1"
. "$here/../../Source/Classes/ProjectCompleter.ps1"
. "$here/../../Source/Classes/ProjectValidateAttribute.ps1"
. "$here/../../Source/Classes/UncachedProjectCompleter.ps1"
. "$here/../../Source/Classes/UncachedProjectValidateAttribute.ps1"
. "$here/../../Source/Classes/VSTeamTask.ps1"
. "$here/../../Source/Classes/VSTeamAttempt.ps1"
. "$here/../../Source/Classes/VSTeamEnvironment.ps1"
. "$here/../../Source/Classes/VSTeamReleaseDefinitions.ps1"
. "$here/../../Source/Classes/VSTeamUserEntitlement.ps1"
. "$here/../../Source/Classes/VSTeamRelease.ps1"
. "$here/../../Source/Classes/VSTeamReleases.ps1"
. "$here/../../Source/Classes/VSTeamBuild.ps1"
. "$here/../../Source/Classes/VSTeamTeams.ps1"
. "$here/../../Source/Classes/VSTeamRepositories.ps1"
. "$here/../../Source/Classes/VSTeamQueues.ps1"
. "$here/../../Source/Classes/VSTeamBuilds.ps1"
. "$here/../../Source/Classes/VSTeamBuildDefinitions.ps1"
. "$here/../../Source/Classes/VSTeamProject.ps1"
. "$here/../../Source/Public/Get-VSTeamProject.ps1"
. "$here/../../Source/Public/$sut"
#endregion

Describe 'Invoke-VSTeamRequest' {
   Mock _getProjects { return @() }
   Mock _hasProjectCacheExpired { return $true }
   
   Context 'Invoke-VSTeamRequest Options' {
      Mock Invoke-RestMethod
      Mock _getInstance { return 'https://dev.azure.com/test' }

      $projectResult = $(Get-Content "$PSScriptRoot\sampleFiles\projectResult.json" | ConvertFrom-Json)

      Mock _callAPI { return $projectResult } -ParameterFilter {
         $Area -eq 'projects' -and
         $id -eq 'testproject' -and
         $Version -eq "$(_getApiVersion Core)" -and
         $IgnoreDefaultProject -eq $true
      }

      It 'options should call API' {
         Invoke-VSTeamRequest -Method Options -NoProject

         Assert-MockCalled Invoke-RestMethod -Exactly -Scope It -Times 1 -ParameterFilter {
            $Method -eq "Options" -and
            $Uri -eq "https://dev.azure.com/test/_apis"
         }
      }

      It 'release should call API' {
         Invoke-VSTeamRequest -Area release -Resource releases -Id 1 -SubDomain vsrm -Version '4.1-preview' -ProjectName testproject -JSON

         Assert-MockCalled Invoke-RestMethod -Exactly -Scope It -Times 1 -ParameterFilter {
            $Uri -eq "https://vsrm.dev.azure.com/test/testproject/_apis/release/releases/1?api-version=4.1-preview"
         }
      }

      It 'AdditionalHeaders should call API' {
         Invoke-VSTeamRequest -Area release -Resource releases -Id 1 -SubDomain vsrm -Version '4.1-preview' -ProjectName testproject -JSON -AdditionalHeaders @{Test = "Test" }

         Assert-MockCalled Invoke-RestMethod -Exactly -Scope It -Times 1 -ParameterFilter {
            $Headers["Test"] -eq 'Test' -and
            $Uri -eq "https://vsrm.dev.azure.com/test/testproject/_apis/release/releases/1?api-version=4.1-preview"
         }
      }

      It 'by Product Id should call API with product id instead of name' {
         Invoke-VSTeamRequest -ProjectName testproject -UseProjectId -Area release -Resource releases -Id 1 -SubDomain vsrm -Version '4.1-preview'

         Assert-MockCalled Invoke-RestMethod -Exactly -Scope It -Times 1 -ParameterFilter {
            $Uri -eq "https://vsrm.dev.azure.com/test/010d06f0-00d5-472a-bb47-58947c230876/_apis/release/releases/1?api-version=4.1-preview"
         }
      }
   }
}