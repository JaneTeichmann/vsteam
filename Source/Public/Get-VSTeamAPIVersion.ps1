function Get-VSTeamAPIVersion {
   [CmdletBinding()]
   [OutputType([System.Collections.Hashtable])]
   param()

   return @{
      Version                     = $(_getApiVersion -Target)
      Build                       = $(_getApiVersion Build)
      Release                     = $(_getApiVersion Release)
      Core                        = $(_getApiVersion Core)
      Git                         = $(_getApiVersion Git)
      DistributedTask             = $(_getApiVersion DistributedTask)
      VariableGroups              = $(_getApiVersion VariableGroups)
      Tfvc                        = $(_getApiVersion Tfvc)
      Packaging                   = $(_getApiVersion Packaging)
      TaskGroups                  = $(_getApiVersion TaskGroups)
      MemberEntitlementManagement = $(_getApiVersion MemberEntitlementManagement)
      ExtensionsManagement        = $(_getApiVersion ExtensionsManagement)
      ServiceFabricEndpoint       = $(_getApiVersion ServiceFabricEndpoint)
      Graph                       = $(_getApiVersion Graph)
      Policy                      = $(_getApiVersion Policy)
   }
}