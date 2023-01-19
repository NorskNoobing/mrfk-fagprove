function New-FolderStructure {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]$Node,
        [string]$Path
    )

    process {
        foreach ($item in $Node) {
            switch ($item.type) {
                disk {
                    $NewPath = $item.name
                }
                folder {
                    $NewPath = $Path + "\" + $item.name
                }
            }

            if ($item.object) {
                New-FolderStructure -Path $NewPath -Node $item.object
            } else {
                New-Item -ItemType Directory -Path $NewPath
            }
        }
    }
}