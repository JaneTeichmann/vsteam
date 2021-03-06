Set-StrictMode -Version Latest

#region include
Import-Module SHiPS

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")

. "$here/../../Source/Classes/VSTeamLeaf.ps1"
. "$here/../../Source/Classes/VSTeamVersions.ps1"
. "$here/../../Source/Classes/VSTeamTeam.ps1"
. "$here/../../Source/Classes/VSTeamProjectCache.ps1"
. "$here/../../Source/Classes/ProjectCompleter.ps1"
. "$here/../../Source/Classes/ProjectValidateAttribute.ps1"
. "$here/../../Source/Private/applyTypes.ps1"
. "$here/../../Source/Private/common.ps1"
. "$here/../../Source/Public/$sut"
#endregion

Describe "VSTeam" {
   $results = [PSCustomObject]@{
      value = [PSCustomObject]@{
         id          = '6f365a7143e492e911c341451a734401bcacadfd'
         name        = 'refs/heads/master'
         description = 'team description'
      }
   }

   $singleResult = [PSCustomObject]@{
      id          = '6f365a7143e492e911c341451a734401bcacadfd'
      name        = 'refs/heads/master'
      description = 'team description'
   }
   
   Context "Get-VSTeam" {
      # Make sure the project name is valid. By returning an empty array
      # all project names are valid. Otherwise, you name you pass for the
      # project in your commands must appear in the list.
      Mock _getProjects { return @() }
   
      Mock _hasProjectCacheExpired { return $true }
      
      Context "services" {
         Mock _getInstance { return 'https://dev.azure.com/test' }
         Mock _getApiVersion { return '1.0-unitTests' } -ParameterFilter { $Service -eq 'Core' }

         Context 'Get-VSTeam with project name' {
            Mock Invoke-RestMethod { return $results }

            It 'Should return teams' {
               Get-VSTeam -ProjectName Test

               # Make sure it was called with the correct URI
               Assert-MockCalled Invoke-RestMethod -Exactly 1 -ParameterFilter {
                  $Uri -eq "https://dev.azure.com/test/_apis/projects/Test/teams?api-version=$(_getApiVersion Core)"
               }
            }
         }

         Context 'Get-VSTeam with project name, with top' {
            Mock Invoke-RestMethod { return $results }

            It 'Should return teams' {
               Get-VSTeam -ProjectName Test -Top 10

               # With PowerShell core the order of the query string is not the
               # same from run to run!  So instead of testing the entire string
               # matches I have to search for the portions I expect but can't
               # assume the order.
               # The general string should look like this:
               # "https://dev.azure.com/test/_apis/projects/Test/teams/?api-version=$(_getApiVersion Core)&`$top=10"
               Assert-MockCalled Invoke-RestMethod -Exactly 1 -ParameterFilter {
                  $Uri -like "https://dev.azure.com/test/_apis/projects/Test/teams*" -and
                  $Uri -like "*api-version=$(_getApiVersion Core)*" -and
                  $Uri -like "*`$top=10*"
               }
            }
         }

         Context 'Get-VSTeam with project name, with skip' {
            Mock Invoke-RestMethod { return $results }

            It 'Should return teams' {
               Get-VSTeam -ProjectName Test -Skip 10

               # Make sure it was called with the correct URI
               Assert-MockCalled Invoke-RestMethod -Exactly 1 -ParameterFilter {
                  $Uri -like "*https://dev.azure.com/test/_apis/projects/Test/teams*" -and
                  $Uri -like "*api-version=$(_getApiVersion Core)*" -and
                  $Uri -like "*`$skip=10*"
               }
            }
         }

         Context 'Get-VSTeam with project name, with top and skip' {
            Mock Invoke-RestMethod { return $results }

            It 'Should return teams' {
               Get-VSTeam -ProjectName Test -Top 10 -Skip 5

               # Make sure it was called with the correct URI
               Assert-MockCalled Invoke-RestMethod -Exactly 1 -ParameterFilter {
                  $Uri -like "*https://dev.azure.com/test/_apis/projects/Test/teams*" -and
                  $Uri -like "*api-version=$(_getApiVersion Core)*" -and
                  $Uri -like "*`$top=10*" -and
                  $Uri -like "*`$skip=5*"
               }
            }
         }

         Context 'Get-VSTeam with specific project and specific team id' {
            Mock Invoke-RestMethod { return $singleResult }

            It 'Should return teams' {
               Get-VSTeam -ProjectName Test -TeamId TestTeamId

               # Make sure it was called with the correct URI
               Assert-MockCalled Invoke-RestMethod -Exactly 1 -ParameterFilter {
                  $Uri -eq "https://dev.azure.com/test/_apis/projects/Test/teams/TestTeamId?api-version=$(_getApiVersion Core)"
               }
            }
         }

         Context 'Get-VSTeam with specific project and specific team Name' {
            Mock Invoke-RestMethod { return $singleResult }

            It 'Should return teams' {
               Get-VSTeam -ProjectName Test -TeamName TestTeamName

               # Make sure it was called with the correct URI
               Assert-MockCalled Invoke-RestMethod -Exactly 1 -ParameterFilter {
                  $Uri -eq "https://dev.azure.com/test/_apis/projects/Test/teams/TestTeamName?api-version=$(_getApiVersion Core)"
               }
            }
         }
      }


      Context "Server" {
         Mock _useWindowsAuthenticationOnPremise { return $true }

         Mock _getInstance { return 'http://localhost:8080/tfs/defaultcollection' }

         Context 'Get-VSTeam with project name on TFS local Auth' {
            Mock Invoke-RestMethod { return $results }

            It 'Should return teams' {
               Get-VSTeam -ProjectName Test

               # Make sure it was called with the correct URI
               Assert-MockCalled Invoke-RestMethod -Exactly 1 -ParameterFilter {
                  $Uri -eq "http://localhost:8080/tfs/defaultcollection/_apis/projects/Test/teams?api-version=$(_getApiVersion Core)"
               }
            }
         }

         Context 'Get-VSTeam with project name, with top on TFS local Auth' {
            Mock Invoke-RestMethod { return $results }

            It 'Should return teams' {
               Get-VSTeam -ProjectName Test -Top 10

               # Make sure it was called with the correct URI
               Assert-MockCalled Invoke-RestMethod -Exactly 1 -ParameterFilter {
                  $Uri -like "*http://localhost:8080/tfs/defaultcollection/_apis/projects/Test/teams?*" -and
                  $Uri -like "*api-version=$(_getApiVersion Core)*" -and
                  $Uri -like "*`$top=10*"
               }
            }
         }

         Context 'Get-VSTeam with project name, with skip on TFS local Auth' {
            Mock Invoke-RestMethod { return $results }

            It 'Should return teams' {
               Get-VSTeam -ProjectName Test -Skip 10

               # Make sure it was called with the correct URI
               Assert-MockCalled Invoke-RestMethod -Exactly 1 -ParameterFilter {
                  $Uri -like "*http://localhost:8080/tfs/defaultcollection/_apis/projects/Test/teams*" -and
                  $Uri -like "*api-version=$(_getApiVersion Core)*" -and
                  $Uri -like "*`$skip=10*"
               }
            }
         }

         Context 'Get-VSTeam with project name, with top and skip on TFS local Auth' {
            Mock Invoke-RestMethod { return $results }

            It 'Should return teams' {
               Get-VSTeam -ProjectName Test -Top 10 -Skip 5

               # Make sure it was called with the correct URI
               Assert-MockCalled Invoke-RestMethod -Exactly 1 -ParameterFilter {
                  $Uri -like "*http://localhost:8080/tfs/defaultcollection/_apis/projects/Test/teams*" -and
                  $Uri -like "*api-version=$(_getApiVersion Core)*" -and
                  $Uri -like "*`$top=10*" -and
                  $Uri -like "*`$skip=5*"
               }
            }
         }

         Context 'Get-VSTeam with specific project and specific team Name on TFS local Auth' {
            Mock Invoke-RestMethod { return $singleResult }

            It 'Should return teams' {
               Get-VSTeam -ProjectName Test -Name TestTeamName

               # Make sure it was called with the correct URI
               Assert-MockCalled Invoke-RestMethod -Exactly 1 -ParameterFilter {
                  $Uri -eq "http://localhost:8080/tfs/defaultcollection/_apis/projects/Test/teams/TestTeamName?api-version=$(_getApiVersion Core)"
               }
            }
         }

         Context 'Get-VSTeam with specific project and specific team ID on TFS local Auth' {
            Mock Invoke-RestMethod { return $singleResult }

            It 'Should return teams' {
               Get-VSTeam -ProjectName Test -TeamId TestTeamId

               # Make sure it was called with the correct URI
               Assert-MockCalled Invoke-RestMethod -Exactly 1 -ParameterFilter {
                  $Uri -eq "http://localhost:8080/tfs/defaultcollection/_apis/projects/Test/teams/TestTeamId?api-version=$(_getApiVersion Core)"
               }
            }
         }
      }
   }
}