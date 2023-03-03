# PlannerAppOnlyPublic

These PowerShell commands show how you would use the recently introduced Application permissions to read all groups and plans,
and not just the ones you have access to normally using delegated permisisons.
These permissions are ideal for reporting scenarios where you want to read all plans and tasks
This just gets all groups, the plans in the groups and the tasks in the plan with minimal properties displayed

In this initial release I don't do any paging or handling of throttling - you may be limited on the groups, plans and tasks
Default paging for groups is 100 and can be increased to 999
The paging for tasks is 400.

The App Registration for this sample needs the following permissions added:
- Group.Read.All
- Tasks.Read.All

I keep my client Id and the secret for the App Registration in KeyVault and the PowerShell shows placeholders for the various items such as:
- Azure tenant Id and subscription name
- KeyVault and names for the id and secrets
- M365 tenant Id

The following links show more details for the calls made:

- [List groups](https://learn.microsoft.com/en-us/graph/api/group-list?view=graph-rest-1.0&tabs=http)
- [List plans](https://learn.microsoft.com/en-us/graph/api/plannergroup-list-plans?view=graph-rest-1.0&tabs=http)
- [List plan tasks](https://learn.microsoft.com/en-us/graph/api/plannerplan-list-tasks?view=graph-rest-1.0&tabs=http)

