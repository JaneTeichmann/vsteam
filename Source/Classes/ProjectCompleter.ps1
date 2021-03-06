using namespace System.Collections
using namespace System.Collections.Generic
using namespace System.Management.Automation

class ProjectCompleter : IArgumentCompleter {
   [IEnumerable[CompletionResult]] CompleteArgument(
      [string] $CommandName,
      [string] $ParameterName,
      [string] $WordToComplete,
      [Language.CommandAst] $CommandAst,
      [IDictionary] $FakeBoundParameters) {

      $results = [List[CompletionResult]]::new()

      if (_hasProjectCacheExpired) {
         [VSTeamProjectCache]::projects = _getProjects
         [VSTeamProjectCache]::timestamp = (Get-Date).Minute
      }

      foreach ($p in [VSTeamProjectCache]::projects) {
         if ($p -like "*$WordToComplete*") {
            $results.Add([CompletionResult]::new($p))
         }
      }

      return $results
   }
}