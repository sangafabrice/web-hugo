$HugoDir = $MyInvocation.MyCommand.Path -replace '\\[^\\]+$'
Set-Location -Path $HugoDir
Hugo completion powershell | Out-String | Invoke-Expression
Set-Location -

Function New-Site {
    Param (
        $Name
    )
    Set-Location -Path $Script:HugoDir
    Hugo new site $Name --format=toml | Out-Null && $(
        New-Item -Path ".\sites\$Name" -ItemType Directory
        $ConfigDir = "$Name\config"
        Move-Item -Path ".\$ConfigDir.toml" -Destination (New-Item -Path ".\$ConfigDir\_default" -ItemType Directory).FullName
        Get-ChildItem -Path config |
        ForEach-Object {
            New-Item -ItemType Junction -Path ".\$ConfigDir\$($_.Name)" -Target $_.FullName
        }
        Remove-Item -Path ".\$Name\themes" -Force
        Set-Location -Path ".\$Name"
        Add-Content -Path .\.gitignore -Value "public`n.hugo_build.lock"
        Git init --initial-branch=main .
        Git add .
        Git commit -m "$($Name): site creation"
        Set-Location -
    ) | Out-Null
    Set-Location -
}

Function Connect-Site {
    Param (
        [Parameter(Mandatory=$true)] $Name,
        $Port = 1313,
        $Environment = 'development'
    )
    Set-Location -Path "${Script:HugoDir}\$Name"
    Hugo server --themesDir=..\themes --destination=.\public --environment=$Environment --port=$Port --cleanDestinationDir
}

Function Deploy-Site {
    Param (
        [Parameter(Mandatory=$true)] $Name,
        $CommitText = "Generate site: $(Get-Date)"
    )
    Set-Location -Path "${Script:HugoDir}\$Name"
    Hugo --themesDir=..\themes --destination=..\sites\$Name --environment=production --minify --cleanDestinationDir
    Git add .
    Git commit -m "$CommitText"
    Set-Location -
}

Export-ModuleMember -Function '*-Site'