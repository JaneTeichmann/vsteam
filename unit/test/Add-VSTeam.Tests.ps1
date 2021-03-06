Set-StrictMode -Version Latest

#region include
Import-Module SHiPS

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")

. "$here/../../Source/Private/common.ps1"
. "$here/../../Source/Classes/VSTeamLeaf.ps1"
. "$here/../../Source/Classes/VSTeamTeam.ps1"
. "$here/../../Source/Classes/VSTeamProjectCache.ps1"
. "$here/../../Source/Classes/ProjectCompleter.ps1"
. "$here/../../Source/Classes/ProjectValidateAttribute.ps1"
. "$here/../../Source/Public/$sut"
#endregion

Describe "VSTeam" {
   Context "Add-VSTeam" {
      $singleResult = Get-Content "$PSScriptRoot\sampleFiles\get-vsteam.json" -Raw | ConvertFrom-Json
      
      Mock _callAPI { return $singleResult }
      Mock _hasProjectCacheExpired { return $false }
      Mock _getApiVersion { return '1.0-unitTests' } -ParameterFilter { $Service -eq 'Core' }

      It 'with team name only should create a team' {
         Add-VSTeam -ProjectName Test -TeamName "TestTeam"

         Assert-MockCalled _callAPI -Exactly -Times 1 -Scope It -ParameterFilter {
            $NoProject -eq $true -and
            $Area -eq 'projects' -and
            $Resource -eq 'Test' -and
            $Method -eq 'Post' -and
            $ContentType -eq 'application/json' -and
            $Body -eq '{ "name": "TestTeam", "description": "" }'
            $Version -eq '1.0-unitTests'
         }
      }

      It 'with team name and description should create a team' {
         Add-VSTeam -ProjectName Test -TeamName "TestTeam" -Description "Test Description"

         Assert-MockCalled _callAPI -Exactly -Times 1 -Scope It -ParameterFilter {
            $NoProject -eq $true -and
            $Area -eq 'projects' -and
            $Resource -eq 'Test' -and
            $Method -eq 'Post' -and
            $ContentType -eq 'application/json' -and
            $Body -eq '{ "name": "TestTeam", "description": "Test Description" }'
            $Version -eq '1.0-unitTests'
         }
      }
   }
}