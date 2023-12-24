function Show-Room {
    <#
    .SYNOPSIS
        Displays the content of the room to screen.

    #>

    Write-Host "DEV: Currentroom: $($State.CurrentRoom)." -ForegroundColor Magenta

    # Write header to screen
    Show-Header
    Write-Host

    # Write previous action to screen
    if ($Action) {
        Write-WordWrapHost $Action -Color Green
        Write-Host
    }

    # Write room title to screen.
    Write-Host "[$($Map."$($State.CurrentRoom)".RoomTitle)]" -BackgroundColor White -ForegroundColor Black
    Write-Host
    
    # Write room description to screen.
    Write-WordWrapHost "$($Map."$($State.CurrentRoom)".RoomDescription)"

    # Write exits to screen.
    Write-Host "[ Exits: $($Map."$($State.CurrentRoom)".exits) ]"
    Write-Host

    # Write room items to screen.
    foreach ($Item in $Map."$($State.CurrentRoom)".Items) {
        #Write-Host "An $Item is here." -ForegroundColor Cyan
        Write-Host "Item: $Item" -ForegroundColor Cyan
        Write-Host "Description: $($Item.ItemDescription)" -ForegroundColor Cyan
    }
    Write-Host
}
