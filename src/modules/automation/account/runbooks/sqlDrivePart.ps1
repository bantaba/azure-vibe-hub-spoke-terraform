#Drive Configure 
$partitionNumber = Get-Disk | Where-Object { $_.PartitionStyle -eq 'RAW' } | Select-Object Number
Initialize-Disk -Number $partitionNumber.Number -PartitionStyle MBR -PassThru

new-partition -disknumber $partitionNumber.Number -usemaximumsize | format-volume -filesystem NTFS -newfilesystemlabel BAK
get-partition -disknumber $partitionNumber.Number | set-partition -newdriveletter E

Get-Partition