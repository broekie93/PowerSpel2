function New-Move {
    <#
    .SYNOPSIS
        Moves the character to a different room.

    .DESCRIPTION
        Moves the character to a different room, if the move is valid (both a room must be present and a wall absent, in the given direction).

    .PARAMETER Direction
        Direction of the room to move to, relative to the current room.

    .EXAMPLE
        ps> New-Move -Direction E

    .NOTES
        Moving works by adjusting the $State.CurrentRoom value. The room coordinates consist of six numbers. The first two numbers are for
        the x-axis (east-west), the second pair for the y-axis (north-south) and the third pair for the z-axis (up-down). This means that
        moving one room up, increases the $State.CurrentRoom variable by one. Moving two rooms south, decreases this variable by 200, etc.
    #>

    param(
        [ValidateSet("N", "E", "S", "W", "U", "D")]
        [string]$Direction
    )

    switch ($Direction) {
        N { 
            [int]$DestinationRoom = $State.CurrentRoom + 100
            $DirectionFull = "North"
            $DefaultMoveMessage = "You walk to the north."
        }
        S { 
            [int]$DestinationRoom = $State.CurrentRoom - 100
            $DirectionFull = "South"
            $DefaultMoveMessage = "You walk to the south."
        }
        E { 
            [int]$DestinationRoom = $State.CurrentRoom + 10000
            $DirectionFull = "East"
            $DefaultMoveMessage = "You walk to the east."
        }
        W { 
            [int]$DestinationRoom = $State.CurrentRoom - 10000
            $DirectionFull = "West"
            $DefaultMoveMessage = "You walk to the west."
        }
        U { 
            [int]$DestinationRoom = $State.CurrentRoom + 1
            $DirectionFull = "Up"
            $DefaultMoveMessage = "You walk up."
        }
        D { 
            [int]$DestinationRoom = $State.CurrentRoom - 1
            $DirectionFull = "Down"
            $DefaultMoveMessage = "You walk down."
        }
    }

    # Check to see if there is a locked door in the Direction and if the player inventory contains the correct key.
    $LockedDoor = $World."$($State.CurrentRoom)".Exits.$DirectionFull.LockedDoor
    $InventoryKeysThatFitThisLock = $State.Inventory | Where-Object { $World."$($State.CurrentRoom)".Exits.$DirectionFull.Key -contains $_}
    if ( $LockedDoor -eq "true" -and ($InventoryKeysThatFitThisLock).Count -eq 0) {
        if ($State.idclip -eq $true) {
            $Script:ActionMessage = "You use your cheat to clip through the door."
            # Change currentroom to the new room
            $State.CurrentRoom = $DestinationRoom
            $State.Steps++
            # Add the new room to the State, for statistics.
            if ($State.RoomsVisited -notcontains $DestinationRoom) {
                $State.RoomsVisited += $DestinationRoom
            }
        }
        else {
            $Script:ActionMessage = "The door in that direction is locked and you lack the key to unlock it."
        }
        return
    }

    # Check to see if there is a room with the correct coordinates in the map, and an exit in the room info which corresponds with the Direction.
    if ($World.Keys -contains $Destinationroom -and (($World."$($State.CurrentRoom)".Exits).$DirectionFull)) {
        # Fill ActionMessage with provided ExitMessage, or the DefaultMoveMessage when no ExitMessage exists.
        if ($null -ne ($World."$($State.CurrentRoom)".Exits).$DirectionFull.ExitMessage) {
            $Script:ActionMessage = ($World."$($State.CurrentRoom)".Exits).$DirectionFull.ExitMessage
        }
        else {
            $Script:ActionMessage = $DefaultMoveMessage
        }
        $State.CurrentRoom = $DestinationRoom
        $State.Steps++
        # Add the new room to the State, for statistics.
        if ($State.RoomsVisited -notcontains $DestinationRoom) {
            $State.RoomsVisited += $DestinationRoom
        }
    }
    else {
        $Script:ActionMessage = "You can't go that way. Try again."
        return
    }
}
