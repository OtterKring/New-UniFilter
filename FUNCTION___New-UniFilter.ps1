<#
.SYNOPSIS
Create a filter for ActiveDirectory or ExchangeManagement cmdlets for a single attribute with multiple values

.DESCRIPTION
Concatenate a series of values to be filtered on a single attribute and
connect the single filters with -and or -or to create one filter (or more, if the JoinLimit is surpassed).
This way only one call to the target system with one filter is required instead of multiple calls for each value.

The resulting filter will respect the syntax of e.g. Get-ADUser or Get-Mailbox cmdlets.

.PARAMETER Attribute
The attribute to filter

MANDATORY

.PARAMETER Operator
The operator used for filtering (eq,ne,le,lt,ge,gt,like,notlike)

MANDATORY

.PARAMETER Value
The value to compare to the attribute.

MANDATORY
PIPELINE enabled

.PARAMETER LogicalJoin
The logical join operator used to join the individual filters together (and, or)

MANDATORY

.PARAMETER JoinLimit
Maximum amount of individual filters to be join together

OPTIONAL
DEFAULT = 25

.EXAMPLE
1234,5678,'unkown' | New-UniFilter -Attribute EmployeeID -Operator eq -LogicalJoin or | %{Get-ADUser -Filter $_}

.EXAMPLE
Get-ADUser -Filter "EmployeeID -gt 1000 -and EmployeeID -lt 2000" | New-UniFilter -Attribute userprincipalname -Operator eq -LogicalJoin or | Foreach -Object {Get-ExoMailbox Filter $_ }

When a full object is piped to the function, -Attribute will define the field where to take the value from.
If the object does not include and attribute with the same name a terminating error will be thrown.

.NOTES
Version 1.0, 2020-09-02:
    Initial Version
Version 2.0, 2020-09-04:
    - added support for input of objects. -Attribute parameter will define which attribute of the piped object will be used.
    - reduced JoinLimit from 100 to 25. Get-EXOMailbox fails already with 50 joined filters

Maximilian Otter, 2020-09-02
Twitter: @Otterkring
#>
function New-UniFilter {
    [CmdletBinding()]
    param (
        # Attribute to filter on
        [Parameter(Mandatory)]
        [string]
        $Attribute,
        # Comparison operator for filter
        [Parameter(Mandatory)]
        [ValidateSet('eq','ne','lt','le','gt','ge','like','notlike')]
        [string]
        $Operator,
        # value to compare, ideally coming from pipeline
        [Parameter(Mandatory,ValueFromPipeline)]
        $InputObject,
        # Join operator concatenate filters
        [Parameter(Mandatory)]
        [ValidateSet('and','or')]
        [string]
        $LogicalJoin,
        # Maximum of individual filters to join together before returning the unifilter
        [Parameter()]
        [byte]
        $JoinLimit = 25
    )
    
    begin {
        $Filters = [System.Collections.Generic.List[string]]::new()
    }
    
    process {

        if ($InputObject -is [string] -or $InputObject -is [valuetype]) {
            if ($InputObject -is [string]) {
                $Value = [string]::Concat("'",$InputObject,"'")
            } else {
                $Value = $InputObject
            }            
        } else {
            if ($InputObject.PSObject.Properties.Name -contains $Attribute) {
                $Value = $InputObject.$Attribute
            } else {
                Throw "InputObject does not contain an attribute `"$Attribute`""
            }            
        }

        $Filters.Add([string]::Concat($Attribute,' -',$Operator,' ',$Value))

        if ($Filters.Count -eq $JoinLimit) {
            [string]::Join(" -$LogicalJoin ",$Filters)
            $Filters.Clear()
        }

    }
    
    end {
        [string]::Join(" -$LogicalJoin ",$Filters)
    }

}