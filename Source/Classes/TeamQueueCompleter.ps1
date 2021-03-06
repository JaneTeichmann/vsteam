using namespace System.Collections
using namespace System.Collections.Generic
using namespace System.Management.Automation

class TeamQueueCompleter : IArgumentCompleter {
   [IEnumerable[CompletionResult]] CompleteArgument(
      [string] $CommandName,
      [string] $ParameterName,
      [string] $WordToComplete,
      [Language.CommandAst] $CommandAst,
      [IDictionary] $FakeBoundParameters) {

      $results = [List[CompletionResult]]::new()

      # If the user has explictly added the -ProjectName parameter
      # to the command use that instead of the default project.
      $projectName = $FakeBoundParameters['ProjectName']

      # Only use the default project if the ProjectName parameter was
      # not used
      if (-not $projectName) {
         $projectName = _getDefaultProject
      }

      # If there is no projectName by this point just return a empty
      # list.
      if ($projectName) {
         foreach ($q in (Get-VSTeamQueue -ProjectName $projectName)) {
            if ($q.name -like "*$WordToComplete*") {
               $results.Add([CompletionResult]::new($q.name))
            }
         }
      }

      return $results
   }
}
