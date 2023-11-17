# Script written by Sean Bikkes 18/10/2023

Write-Host "                                   "
Write-Host "            ---------              "
Write-Host "           / .  '  . \             "
Write-Host "           -----------             "
Write-Host "          < ~~~~~~~~~ >            "
Write-Host "           -----------             "
Write-Host "           \. '  .  '/             "
Write-Host "             -------               "
Write-Host "    Welcome to MAC_Hunt3R 0.96     "
Write-Host "                                   "



# Define the path to the "getIPfromMAC.ps1" script
$scriptPath = ".\getIPfromMAC.ps1"
# Initialise global

while($True) {
    Write-Host "Copy MAC addresses into clipboard (don't paste into console) and press enter,"
    $cmd = Read-Host "OR type in regex as input for MAC search in format XX-XX-XX-XX-XX-XX OR q to quit..."
    $regexCmd = $False    
    if ($cmd -eq "q")
    {
        Write-Host "Exiting..."
        Exit 0
    }
    # If there is any input
    if (-not ($cmd.Length -gt 1))
    {
        Write-Host "Searching for contents in clipboard..."
        $inputTextRaw = Get-Clipboard
        $inputTextCooked = $inputTextRaw -split "`n"
    }
    else{
        Write-Host "Searching for inputted expression..."
        $inputTextCooked = $cmd
        $regexCmd = $True
    }

    # Init
    $leases = $null
    $switchPortNumbers = @()
    $macAddressArray = @()

    $dhcpServers = Get-Content "./servers.txt"
    # reset from the last iteration
    foreach($dhcpServer in $dhcpServers){
        Write-Host "Fetching scopes from $dhcpServer..."
        $scopes = Get-DhcpServerv4Scope -ComputerName $dhcpServer
        Write-Host "Fetching leases from $dhcpServer in all scopes..."
        $leases += $scopes | Get-DhcpServerv4Lease -ComputerName $dhcpServer
    }
    # Extract MACs with regex
    if ($regexCmd -eq $False)
    {
        foreach ($line in $inputTextCooked){
            $matches = $line | Select-String -Pattern '([0-9A-Fa-f]{4}(?:\.[0-9A-Fa-f]{4}){2})' -AllMatches | ForEach-Object { $_.Matches.Value }
            $macAddressArray += $matches
            $matches = $line | Select-String -Pattern '([FfGg][AaIi]\d+/\d+(/\d+)?)' -AllMatches | ForEach-Object {$_.Matches.Value}
            # Extract Port Number with regex
            $switchPortNumbers += $matches

        }
    }
    else
    {
        $macAddressArray +=$inputTextCooked
    }

    $switchportIndex = 0
    $filteredLeases = @()

    # Iterate through each MAC address and format it as "00-00-00-00-00-00" 
    # before invoking the script

    foreach ($macAddress in $macAddressArray) {
        if ($regexCmd -eq $False)
        {
            $formattedMacAddress = $macAddress -replace '\.', ''
            $formattedMacAddress = $formattedMacAddress -replace '(.{2})(?!$)', '$1-'
        }
        else
        {
            $formattedMacAddress = $macAddress
            $filteredLeases = $leases | Where-Object {$_.ClientId -like $formattedMacAddress}
            break
        }

        $leaseSearch = $leases | Where-Object {$_.ClientId -like $formattedMacAddress}

        # Yeah I still don't know what the fuck is going on here.
        if ($leaseSearch -ne $null){
            $filteredLeases += $leaseSearch[0]
        }
        else
        {
                $filteredLeases += "No lease found for: $formattedMacAddress"
        }
    }

    # Build a finished and organised list from the ungrouped list
    $finishedItemIndex = 0
    $finishedLeaseList = @()
    $finishedPortList = @()
    # Loop through each lease we have.
    # The indices should map 1:1 with the port strings.
    foreach ($lease in $filteredLeases) {
        # Did this lease already end up in the final list at some point?
        # If so, then skip to next one.
        $alreadyTransferred = $False
        foreach ($l in $finishedLeaseList) {
            if ($l -eq $lease)
            {
                $alreadyTransferred = $True
                break
            }
        }
        if ($alreadyTransferred -eq $True)
        {
            $finishedItemIndex++
            continue
        }

        # We have an original lease and port number, add them to the final list
        $finishedLeaseList += $lease
        $finishedPortList += $switchPortNumbers[$finishedItemIndex]

        # Now hunt for any lease with the same port number and add those onto the final list
        $num = $switchPortNumbers[$finishedItemIndex]
        $i = 0
        foreach($port in $switchPortNumbers) {
            if (($port -like $num))
            {
                if (-not($i -eq $finishedItemIndex))
                {
                    $finishedLeaseList += $filteredLeases[$i]
                    $finishedPortList += $switchPortNumbers[$i]
                }
            }
            $i++
        }
        $finishedItemIndex++
    }

    # Just print all the shit out
    $i = 0
    foreach ($lease in $finishedLeaseList) {
        $lease
        $last = $i-1
        $next = $i+1
        if (-not($finishedPortList[$i] -like $finishedPortList[$next])){
            $port = $finishedPortList[$i]
            Write-Host "Switch Port $port"
        }
        $i++
    }
    Write-Host "Done!"
}