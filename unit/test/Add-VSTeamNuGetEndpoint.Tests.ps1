Set-StrictMode -Version Latest

#region include
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")

. "$here/../../Source/Classes/VSTeamVersions.ps1"
. "$here/../../Source/Classes/VSTeamProjectCache.ps1"
. "$here/../../Source/Private/applyTypes.ps1"
. "$here/../../Source/Private/common.ps1"
. "$here/../../Source/Public/Add-VSTeamServiceEndpoint.ps1"
. "$here/../../Source/Public/Get-VSTeamServiceEndpoint.ps1"
. "$here/../../Source/Classes/ProjectCompleter.ps1"
. "$here/../../Source/Classes/ProjectValidateAttribute.ps1"
. "$here/../../Source/Public/$sut"
#endregion

Describe 'VSTeamNuGetEndpoint' {
   Context 'Add-VSTeamNuGetEndpoint' {
      Mock _hasProjectCacheExpired { return $false }

      Mock _getInstance { return 'https://dev.azure.com/test' }

      Mock _getApiVersion { return '1.0-unitTests' } -ParameterFilter { $Service -eq 'DistributedTask' }
      Mock _getApiVersion { return '1.0-unitTests' } -ParameterFilter { $Service -eq 'ServiceFabricEndpoint' }

      Mock Write-Progress
      Mock Invoke-RestMethod { return @{id = '23233-2342' } } -ParameterFilter { $Method -eq 'Post' }
      Mock Invoke-RestMethod {
         # This $i is in the module. Because we use InModuleScope
         # we can see it
         if ($iTracking -gt 9) {
            return [PSCustomObject]@{
               isReady         = $true
               operationStatus = [PSCustomObject]@{state = 'Ready' }
            }
         }

         return [PSCustomObject]@{
            isReady         = $false
            createdBy       = [PSCustomObject]@{ }
            authorization   = [PSCustomObject]@{ }
            data            = [PSCustomObject]@{ }
            operationStatus = [PSCustomObject]@{state = 'InProgress' }
         }
      }

      It 'with ApiKey should create a new NuGet Serviceendpoint' {
         Add-VSTeamNuGetEndpoint -ProjectName 'project' -EndpointName 'PowerShell Gallery' -NuGetUrl 'https://www.powershellgallery.com/api/v2/package' -ApiKey '00000000-0000-0000-0000-000000000000'
         Assert-MockCalled Invoke-RestMethod -Exactly -Scope Context -Times 1 -ParameterFilter {
            $Uri -eq "https://dev.azure.com/test/project/_apis/distributedtask/serviceendpoints?api-version=$(_getApiVersion DistributedTask)" -and
            $Method -eq 'Post' -and
            $ContentType -eq 'application/json' -and
            $Body -like '*"nugetkey": *"00000000-0000-0000-0000-000000000000"*' -and
            $Body -like '*"scheme": *"None"*'
         }
      }

      It 'with Username and Password should create a new NuGet Serviceendpoint' {
         $password = '00000000-0000-0000-0000-000000000000' | ConvertTo-SecureString -AsPlainText -Force
         Add-VSTeamNuGetEndpoint -ProjectName 'project' -EndpointName 'PowerShell Gallery' -NuGetUrl 'https://www.powershellgallery.com/api/v2/package' -Username 'testUser' -SecurePassword $password

         Assert-MockCalled Invoke-RestMethod -Exactly -Scope Context -Times 1 -ParameterFilter {
            $Uri -eq "https://dev.azure.com/test/project/_apis/distributedtask/serviceendpoints?api-version=$(_getApiVersion DistributedTask)" -and
            $Method -eq 'Post' -and
            $ContentType -eq 'application/json' -and
            $Body -like '*"username": *"testUser"*' -and
            $Body -like '*"password": *"00000000-0000-0000-0000-000000000000"*' -and
            $Body -like '*"scheme": *"UsernamePassword"*'
         }
      }

      It 'with Token should create a new NuGet Serviceendpoint' {
         Add-VSTeamNuGetEndpoint -ProjectName 'project' -EndpointName 'PowerShell Gallery' -NuGetUrl 'https://www.powershellgallery.com/api/v2/package' -PersonalAccessToken '00000000-0000-0000-0000-000000000000'
         Assert-MockCalled Invoke-RestMethod -Exactly -Scope Context -Times 1 -ParameterFilter {
            $Uri -eq "https://dev.azure.com/test/project/_apis/distributedtask/serviceendpoints?api-version=$(_getApiVersion DistributedTask)" -and
            $Method -eq 'Post' -and
            $ContentType -eq 'application/json' -and
            $Body -like '*"apitoken":*"00000000-0000-0000-0000-000000000000"*' -and
            $Body -like '*"scheme":*"Token"*'
         }
      }
   }
}