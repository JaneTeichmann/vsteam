Set-StrictMode -Version Latest

#region include
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")

. "$here/../../Source/Classes/VSTeamVersions.ps1"
. "$here/../../Source/Classes/VSTeamProjectCache.ps1"
. "$here/../../Source/Classes/ProjectCompleter.ps1"
. "$here/../../Source/Classes/ProjectValidateAttribute.ps1"
. "$here/../../Source/Private/common.ps1"
. "$here/../../Source/Public/$sut"
#endregion

Describe 'VSTeamBuildTag' {
   Context 'Remove-VSTeamBuildTag' {
      [string[]] $inputTags = "Test1", "Test2", "Test3"
      Mock Invoke-RestMethod { return @{ value = $null } }

      Context 'Services' {
         # Set the account to use for testing. A normal user would do this
         # using the Set-VSTeamAccount function.
         Mock _getInstance { return 'https://dev.azure.com/test' }

         # Mock the call to Get-Projects by the dynamic parameter for ProjectName
         Mock Invoke-RestMethod { return @() } -ParameterFilter {
            $Uri -like "*_apis/projects*"
         }

         It 'should add tags to Build' {
            Remove-VSTeamBuildTag -ProjectName project -id 2 -Tags $inputTags

            foreach ($inputTag in $inputTags) {
               Assert-MockCalled Invoke-RestMethod -Exactly -Scope It -Times 1 -ParameterFilter {
                  $Method -eq 'Delete' -and
                  $Uri -eq "https://dev.azure.com/test/project/_apis/build/builds/2/tags?api-version=$(_getApiVersion Build)" + "&tag=$inputTag"
               }
            }
         }
      }

      Context 'Server' {
         Mock _useWindowsAuthenticationOnPremise { return $true }

         # Mock the call to Get-Projects by the dynamic parameter for ProjectName
         Mock Invoke-RestMethod { return @() } -ParameterFilter {
            $Uri -like "*_apis/projects*"
         }

         Mock _getInstance { return 'http://localhost:8080/tfs/defaultcollection' }

         It 'should add tags to Build' {      
            Remove-VSTeamBuildTag -ProjectName project -id 2 -Tags $inputTags

            foreach ($inputTag in $inputTags) {
               Assert-MockCalled Invoke-RestMethod -Exactly -Scope It -Times 1 -ParameterFilter {
                  $Method -eq 'Delete' -and
                  $Uri -eq "http://localhost:8080/tfs/defaultcollection/project/_apis/build/builds/2/tags?api-version=$(_getApiVersion Build)" + "&tag=$inputTag"
               }
            }
         }
      }
   }
}