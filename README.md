# PS_New-UniFilter
create one filter for checking many value on one attribute

## Why?

Active Directory and Exchange (as well as other server systems) are very fast internally but a single call to those system takes time.
Many calls take a lot of time!

Example:

You want to get users matching a list of EmployeeIDs. EmployeeIDs is a non-indexed attribute in AD which makes the call extra slow.

If you run ...

    '10001','10020','10032' | Foreach-Object { Get-ADUser -Filter "EmployeeID -eq '$_'" -Properties EmployeeID } | Select-Object Name,EmployeeID
    
... you create 3 calls (usually your list is longer, but just for the example).

You coud write ...

    Get-ADUser -Filter "EmployeeID -eq '10001' -or EmployeeID -eq '10020' -or EmployeeID -eq '10032'" -Properties EmployeeID | Select-Object Name,EmployeeID
    
... the call will be quite a bit faster, but writing the filter is tedious.


## HowTo

The function `New-UniFilter` does all the filter building work for you:

    '10001','10020','10032' | New-UniFilter -Attribute EmployeeID -Operator eq -LogicalJoin or
    
... will produce:

    "EmployeeID -eq '10001' -or EmployeeID -eq '10020' -or EmployeeID -eq '10032'"


The filter length is limited to 25 clauses but can be manually overwritten using the `-JoinLimit` parameter. There is a hardcoded limit in the cmdlets, though, so don't get too excited about it. :-)

In the end our example from above will look like:

    '10001','10020','10032' | New-UniFilter -Attribute EmployeeID -Operator eq -LogicalJoin or | Foreach-Object { Get-ADUser -Filter $_ -Properties EmployeeID } | Select-Object Name,EmployeeID
