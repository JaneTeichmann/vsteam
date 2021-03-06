﻿Set-StrictMode -Version Latest

#region include
Import-Module SHiPS

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")

. "$here/../../Source/Classes/VSTeamLeaf.ps1"
. "$here/../../Source/Classes/VSTeamDirectory.ps1"
. "$here/../../Source/Classes/VSTeamVersions.ps1"
. "$here/../../Source/Private/common.ps1"
. "$here/../../Source/Classes/VSTeamProjectCache.ps1"
. "$here/../../Source/Classes/VSTeamUserEntitlement.ps1"
. "$here/../../Source/Classes/VSTeamTeams.ps1"
. "$here/../../Source/Classes/VSTeamRepositories.ps1"
. "$here/../../Source/Classes/VSTeamReleaseDefinitions.ps1"
. "$here/../../Source/Classes/ProjectCompleter.ps1"
. "$here/../../Source/Classes/ProjectValidateAttribute.ps1"
. "$here/../../Source/Classes/UncachedProjectCompleter.ps1"
. "$here/../../Source/Classes/UncachedProjectValidateAttribute.ps1"
. "$here/../../Source/Classes/VSTeamSecurityNamespace.ps1"
. "$here/../../Source/Classes/VSTeamPermissionInheritance.ps1"
. "$here/../../Source/Classes/VSTeamTask.ps1"
. "$here/../../Source/Classes/VSTeamAttempt.ps1"
. "$here/../../Source/Classes/VSTeamEnvironment.ps1"
. "$here/../../Source/Classes/VSTeamRelease.ps1"
. "$here/../../Source/Classes/VSTeamReleases.ps1"
. "$here/../../Source/Classes/VSTeamBuild.ps1"
. "$here/../../Source/Classes/VSTeamBuilds.ps1"
. "$here/../../Source/Classes/VSTeamPool.ps1"
. "$here/../../Source/Classes/VSTeamQueue.ps1"
. "$here/../../Source/Classes/VSTeamQueues.ps1"
. "$here/../../Source/Classes/VSTeamBuildDefinitionProcessPhaseStep.ps1"
. "$here/../../Source/Classes/VSTeamBuildDefinitionProcessPhase.ps1"
. "$here/../../Source/Classes/VSTeamBuildDefinitionProcess.ps1"
. "$here/../../Source/Classes/VSTeamProject.ps1"
. "$here/../../Source/Classes/VSTeamGitRepository.ps1"
. "$here/../../Source/Classes/VSTeamBuildDefinition.ps1"
. "$here/../../Source/Classes/VSTeamBuildDefinitions.ps1"
. "$here/../../Source/Public/Get-VSTeamProject.ps1"
. "$here/../../Source/Public/Get-VSTeamBuildDefinition.ps1"
. "$here/../../Source/Public/Get-VSTeamReleaseDefinition.ps1"
. "$here/../../Source/Public/Get-VSTeamGitRepository.ps1"
. "$here/../../Source/Public/Get-VSTeamAccessControlList.ps1"
. "$here/../../Source/Public/$sut"
#endregion

Describe 'VSTeamPermissionInheritance' {
   $gitRepoResult = Get-Content "$PSScriptRoot\sampleFiles\singleGitRepo.json" -Raw | ConvertFrom-Json
   $buildDefresults = Get-Content "$PSScriptRoot\sampleFiles\buildDefAzD.json" -Raw | ConvertFrom-Json
   $releaseDefresults = Get-Content "$PSScriptRoot\sampleFiles\releaseDefAzD.json" -Raw | ConvertFrom-Json
   $accesscontrollistsResult = Get-Content "$PSScriptRoot\sampleFiles\repoAccesscontrollists.json" -Raw | ConvertFrom-Json  
   $gitRepoHierarchyUpdateResults = Get-Content "$PSScriptRoot\sampleFiles\gitReopHierarchyQuery_Update.json" -Raw | ConvertFrom-Json
   $buildDefHierarchyUpdateResults = Get-Content "$PSScriptRoot\sampleFiles\buildDefHierarchyQuery_Update.json" -Raw | ConvertFrom-Json
   $releaseDefHierarchyUpdateResults = Get-Content "$PSScriptRoot\sampleFiles\releaseDefHierarchyQuery_Update.json" -Raw | ConvertFrom-Json

   $singleResult = [PSCustomObject]@{
      name        = 'Project'
      description = ''
      url         = ''
      id          = '123-5464-dee43'
      state       = ''
      visibility  = ''
      revision    = 0
      defaultTeam = [PSCustomObject]@{ }
      _links      = [PSCustomObject]@{ }
   }

   Mock _getInstance { return 'https://dev.azure.com/test' }
   Mock _getApiVersion { return '1.0-unitTests' } -ParameterFilter { $Service -eq 'Build' -or $Service -eq 'Release' -or $Service -eq 'Git' }

   # Mock the call to Get-Projects by the dynamic parameter for ProjectName
   Mock Invoke-RestMethod { return @() } -ParameterFilter { $Uri -like "*_apis/projects*" }

   Mock _callAPI { return $singleResult } -ParameterFilter {
      $Area -eq 'projects' -and
      $id -eq 'project' -and
      $Version -eq "$(_getApiVersion Core)" -and
      $IgnoreDefaultProject -eq $true
   }

   Mock _useWindowsAuthenticationOnPremise { return $true }
   
   Context 'Set-VSTeamPermissionInheritance buildDef' {
      Mock _callAPI { return $buildDefresults } -ParameterFilter {
         $Area -eq 'build' -and
         $Resource -eq 'definitions' -and
         $Version -eq "$(_getApiVersion Build)"
      }

      Mock Invoke-RestMethod {
         # If this test fails uncomment the line below to see how the mock was called.
         # Write-Host $args
         # Write-Host $(_getApiVersion Build)

         return $buildDefHierarchyUpdateResults
      }

      It 'should return true' {
         Set-VSTeamPermissionInheritance -projectName project -Name dynamTest-Docker-CI -resourceType BuildDefinition -NewState $false -Force

         Assert-MockCalled Invoke-RestMethod -Exactly -Scope It -Times 1 -ParameterFilter {
            $Method -eq 'Post' -and
            $Body -like '*123-5464-dee43/1432*' -and
            $Body -like '*33344d9c-fc72-4d6f-aba5-fa317101a7e9*' -and
            $Uri -like "*https://dev.azure.com/test/_apis/Contribution/HierarchyQuery/123-5464-dee43*" -and
            $Uri -like "*api-version=$(_getApiVersion Build)*"
         }
      }
   }

   Context 'Set-VSTeamPermissionInheritance releaseDef' {
      Mock Get-VSTeamReleaseDefinition { return $releaseDefresults.value }
      Mock Invoke-RestMethod {
         # If this test fails uncomment the line below to see how the mock was called.
         # Write-Host $args
         # Write-Host $(_getApiVersion Release)

         return $releaseDefHierarchyUpdateResults
      }

      It 'should return true' {
         Set-VSTeamPermissionInheritance -projectName project -Name PTracker-CD -resourceType ReleaseDefinition -NewState $false -Force

         Assert-MockCalled Invoke-RestMethod -Exactly -Scope It -Times 1 -ParameterFilter {
            $Method -eq 'Post' -and
            $Body -like '*c788c23e-1b46-4162-8f5e-d7585343b5de*' -and
            $Body -like '*123-5464-dee43//2*' -and
            $Uri -like "*https://dev.azure.com/test/_apis/Contribution/HierarchyQuery/123-5464-dee43*" -and
            $Uri -like "*api-version=$(_getApiVersion Release)*"
         }
      }
   }

   Context 'Set-VSTeamPermissionInheritance repository' {
      Mock Get-VSTeamGitRepository { return $gitRepoResult }
      Mock Get-VSTeamAccessControlList { return $accesscontrollistsResult.value }

      Mock Invoke-RestMethod {
         # If this test fails uncomment the line below to see how the mock was called.
         #Write-Host $args
         #Write-Host $(_getApiVersion Git)

         return $gitRepoHierarchyUpdateResults
      }

      It 'should return true' {
         Set-VSTeamPermissionInheritance -projectName project -Name project -resourceType Repository -NewState $false -Force

         Assert-MockCalled Invoke-RestMethod -Exactly -Scope It -Times 1 -ParameterFilter {
            $Method -eq 'Post' -and
            $Body -like '*2e9eb7ed-3c0a-47d4-87c1-0ffdd275fd87*' -and
            $Body -like '*repoV2/123-5464-dee43/00000000-0000-0000-0000-000000000001*' -and
            $Uri -like "*https://dev.azure.com/test/_apis/Contribution/HierarchyQuery/123-5464-dee43*" -and
            $Uri -like "*api-version=$(_getApiVersion Git)*"
         }
      }
   }
}