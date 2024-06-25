<# This script updates links between work items in Azure DevOps.
    
    An Input File (.csv) in the format below needs to be 
    provided in the root folder. 
    ---------------------------
    Example:
    Source,Target
    1233,1001
    "#>
[CmdletBinding()]
param (
        [Parameter(Mandatory = $true)]$ado_pat_token,
        [Parameter(Mandatory = $true)]$inputfile,
        [Parameter(Mandatory = $true)]$organization,
        [Parameter(Mandatory = $true)]$projectname
    )

$input_file = Import-Csv .\$inputfile -Delimiter ","
 
 function workingfunc($source,$target){  
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logfile = "UpdateLinks.csv"
    $pat = $ado_pat_token
    $ado_authentication_header = @{  
        'Authorization' = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($pat)"))
        'ContentType' = 'application/json-json+patch'
    }

    $update_field = "https://dev.azure.com/$($organization)/_apis/wit/workitems/$($source)"+"?api-version=7.2-preview.3"
    
    $url_value = "https://dev.azure.com/$($organization)/$($projectname)/_apis/wit/workItems/$($target)"
    #write-host "url_source_value " $update_field
    #write-host "url_target_value" $url_value
    $body = @(@(
    <#The api is found to run successfuly if passed with more than one items in this array
    Please modify accordingly if this changes in futre #>
    
    [ordered]@{
        op = 'add'
        path = '/relations/-'
        value = @{
          rel = 'System.LinkTypes.Related'
          url =  "$url_value"
          
        }
      }
      [ordered] @{
        op = 'add'
        path = '/fields/System.Tags'
        value = "devops"
      }  
   
   
    ) ) | ConvertTo-Json
    #write-host $body
    try {
        #Invoke-RestMethod -Uri "https://dev.azure.com/{OrgName}/{ProjectName}/_apis/wit/workitems/{WorkItemId}?api-version=6.0" -Method 'PATCH' -Body $body -Headers $ado_authentication_header -ContentType 'application/json-patch+json'
        $out = Invoke-RestMethod -Uri $update_field -Method 'PATCH' -Body $body -Headers $ado_authentication_header -ContentType 'application/json-patch+json'
        #$output = "$($get_areapath_file.Issue_key) : " + $response
        $result = "$($timestamp);[Success]:;Updated;$($target);with link;$($source)"
        
        Out-File -FilePath .\$logfile -InputObject $result -Append -Force  
    }
    catch{
        $result = "$($timestamp);[Fail]:;Failure while updating;$($target); link to;$($source);error=;$($_)"
        Out-File  -FilePath .\$logfile  -InputObject $result -Append -Force
    }  
    write-host $result
}
function main{
    foreach ($row in $input_file){
        $source_wit_id = $row.Source
        $target_wit_ids = ($row.Target).Split(",")
        foreach ($target_wit_id in $target_wit_ids){
            workingfunc $source_wit_id $target_wit_id.Trim()
        }
    }
 }

 main
