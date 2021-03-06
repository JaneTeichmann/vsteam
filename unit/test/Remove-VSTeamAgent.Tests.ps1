Set-StrictMode -Version Latest

#region include
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")

. "$here/../../Source/Classes/VSTeamVersions.ps1"
. "$here/../../Source/Classes/VSTeamProjectCache.ps1"
. "$here/../../Source/Classes/ProjectValidateAttribute.ps1"
. "$here/../../Source/Private/common.ps1"
. "$here/../../Source/Public/$sut"
#endregion

Describe 'Remove-VSTeamAgent' {
   Mock _getInstance { return 'https://dev.azure.com/test' } -Verifiable
   [VSTeamVersions]::DistributedTask = '1.0-unitTest'
   
   # Mock the call to Get-Projects by the dynamic parameter for ProjectName
   Mock Invoke-RestMethod { return @() } -ParameterFilter {
      $Uri -like "*_apis/projects*"
   }

   Context 'Remove-VSTeamAgent by ID' {
      Mock Invoke-RestMethod

      It 'should remove the agent with passed in Id' {
         Remove-VSTeamAgent -Pool 36 -Id 950 -Force

         Assert-MockCalled Invoke-RestMethod -Exactly -Scope It -Times 1 -ParameterFilter {
            $Method -eq 'Delete' -and
            $Uri -eq "https://dev.azure.com/test/_apis/distributedtask/pools/36/agents/950?api-version=$(_getApiVersion DistributedTask)"
         }
      }
   }

   Context 'Remove-VSTeamAgent throws' {
      Mock Invoke-RestMethod { throw 'boom' }

      It 'should remove the agent with passed in Id' {
         { Remove-VSTeamAgent -Pool 36 -Id 950 -Force } | Should Throw
      }
   }
}