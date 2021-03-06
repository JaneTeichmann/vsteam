using namespace System.Collections
using namespace System.Collections.Generic
using namespace System.Management.Automation

class UncachedProjectCompleter : IArgumentCompleter {
   [IEnumerable[CompletionResult]] CompleteArgument(
      [string] $CommandName, 
      [string] $ParameterName, 
      [string] $WordToComplete,
      [Language.CommandAst] $CommandAst, 
      [IDictionary] $FakeBoundParameters) {

      $results = [List[CompletionResult]]::new()
      
      [VSTeamProjectCache]::projects = _getProjects
      [VSTeamProjectCache]::timestamp = (Get-Date).Minute
      
      foreach ($p in [VSTeamProjectCache]::projects) {
         if ($p -like "*$WordToComplete*" -and $p -match "\s") {
            $results.Add([CompletionResult]::new("'$p'"))
         }
         elseif ($p -like "*$WordToComplete*") {
            $results.Add([CompletionResult]::new($p))
         }
      } 
      
      return $results
   }
}
