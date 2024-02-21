# PlannerAppOnlyPublic

These PowerShell commands show how you would use the recently introduced Application permissions to read all groups and plans,
and not just the ones you have access to normally using delegated permisisons.
These permissions are ideal for reporting scenarios where you want to read all plans and tasks
This just gets all groups, the plans in the groups and the tasks in the plan with minimal properties displayed

In this initial release I don't do any  handling of throttling but I have added page handling
Default paging for groups is 100 and can be increased to 999
The paging for tasks is 400 - tested on a plan with 2000+ ok.

The App Registration for this sample needs the following application permissions added:
- Group.Read.All
- Tasks.Read.All

For the sample that checks for owners who are not members, and then offers to add members additional application permissions are required:

- GroupMember.ReadWrite.All
- User.ReadWrite.All

I keep my client Id and the secret for the App Registration in KeyVault and the PowerShell shows placeholders for the various items such as:
- Azure tenant Id and subscription name
- KeyVault and names for the id and secrets
- M365 tenant Id

The following links show more details for the calls made:

- [List groups](https://learn.microsoft.com/en-us/graph/api/group-list?view=graph-rest-1.0&tabs=http)
- [List plans](https://learn.microsoft.com/en-us/graph/api/plannergroup-list-plans?view=graph-rest-1.0&tabs=http)
- [List plan tasks](https://learn.microsoft.com/en-us/graph/api/plannerplan-list-tasks?view=graph-rest-1.0&tabs=http)

The most recent additions to the scripts are aimed at helping if the situation arises that Groups are created with owners who are not also members.  This can give issues with Planner and Project as being a member is required and owners are not assumed members.  The scripts require to be run with the right app registration to allow all groups to be seen.  The output is a csv file that shows group with owners who are not members.  This csv file can then be used as input to the 'Process Output' script to add these owners as members too.  The csv could be edited if rows need to be removed if it is still desired that some owners are not members in some groups.

Entra is the usual Group creation methid that can lead to this situation - as Teams now adds a person as both an owner and member, never just owner.  For reference if this is to be corrected manually, both Entra and OWA (via Manage Groups) allow you to do this - but not the Teams admin center.