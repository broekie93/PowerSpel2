<#
.SYNOPSIS
    Starts a game of PowerSpel.

.DESCRIPTION
    Starts a game of PowerSpel. Walk through a world in this text-based adventure, styled after the Multi-User Dungeons that were popular in the nineties.

.PARAMETER Game
    Choose the game mode here. Valid options:
    - Tutorial (get to know the game and its controls)
    - Pentest (the original PowerSpel game)
    Defaults to the tutorial for easy starting.

.PARAMETER Map
    Choose the map type, or turn it off. Valid options: 
    - Static (puts the current floor on the map view and lets the player marker walk around in that).
    - Dynamic (puts the player marker in the middle of the map view and draws the map around it).
    - Off (turns off the map entirely).
    The map style is set by the game in Initialize-Game. If the Map parameter is used, it overwrites the game's default.

.EXAMPLE
    ps> Start-PowerSpel.ps1 -Game Tutorial
    Starts the tutorial of PowerSpel

    ps> Start-PowerSpel.ps1 -Game Pentest -Map Dynamic
    Starts a game of PowerSpel Pentest, forcing the map to be dynamic.

.NOTES
    Written by:       Jelle the Graaf (The Netherlands).
    Source on Github: https://github.com/JelleGraaf/PowerSpel2
#>

param (
    [ValidateSet("Tutorial", "Pentest")]
    [string]$Game = "Tutorial",

    [ValidateSet("Static", "Dynamic", "Off")]
    [string]$Map
)

$ErrorActionPreference = "inquire"

#########################################
#region INITIALIZATION                  #
#########################################

# Import general helper functions.
$GeneralHelpers = Get-ChildItem -Path $PSScriptRoot\Helpers\
foreach ($GeneralHelper in $GeneralHelpers) {
    . $GeneralHelper.fullname
}

# Import game helper functions.
$GameHelpers = Get-ChildItem -Path $PSScriptRoot\Games\$Game\Helpers -File
foreach ($GameHelper in $GameHelpers) {
    . $GameHelper.fullname -force
}

# Import game interactables functions.
$Interactables = Get-ChildItem -Path $PSScriptRoot\Games\$Game\Interactables -File -Filter "*.ps1"
foreach ($Interactable in $Interactables) {
    . $Interactable.fullname
}

# Load global setting for the chosen game.
Initialize-Game

# Overwrite map style with parameter value (if any).
if ($Map) { 
    $MapStyle = $Map
}

# Force console colors.
$Console = $Host.UI.RawUI
$Console.ForegroundColor = "White"
$Console.BackgroundColor = "Black"

# Import rooms.
$Rooms = Get-ChildItem -Path "$PSScriptRoot\Games\$Game\Rooms\" -File -Recurse | Where-Object { $_.Name -ne "_RoomTemplate.json" }

# Prepare variables.
$World = @{}
foreach ($Room in $Rooms) {
    $RoomCoordinates = $Room.Name.Substring(4).Split('.')[0]
    $World.$RoomCoordinates = Get-Content $Room | ConvertFrom-Json -AsHashtable
}

$State = @{
    CurrentRoom              = $StartRoom
    Inventory                = @() # Don't fill this with text longer than the respective header column, or it will mess up the visualization.
    Exploits                 = @() # Don't fill this with text longer than the respective header column, or it will mess up the visualization.
    Achievements             = @() # Don't fill this with text longer than the respective header column, or it will mess up the visualization.
    RoomsVisited             = @($StartRoom)
    Steps                    = 0
    WalkAlongSequenceCounter = 0
}

if (Test-Path "$PSScriptRoot\Games\$Game\Data\GameAchievements.json") {
    $GameAchievements = Get-Content "$PSScriptRoot\Games\$Game\Data\GameAchievements.json" | ConvertFrom-Json -AsHashtable
}
if (Test-Path "$PSScriptRoot\Games\$Game\Data\GameExploits.json") {
    $GameExploits = Get-Content "$PSScriptRoot\Games\$Game\Data\GameExploits.json" | ConvertFrom-Json -AsHashtable
}

$GameState = "Running"
$StartTime = Get-Date

#endregion initialization


#########################################
#region MAIN GAME                       #
#########################################

# Start the game with a splash screen.
Show-StartScreen

# Main game loop.
while ($GameState -ne "Quit") {
    # Take inventory of all the objects (items and interactables) in the current room.
    $RoomObjects = @{}
    $i = 1
    foreach ($Item in $World."$($State.CurrentRoom)".Items.Keys) {
        $RoomObjects.$i = $World."$($State.CurrentRoom)".Items.$Item
        $i++
    }
    foreach ($Interactable in $World."$($State.CurrentRoom)".Interactables.Keys) {
        $RoomObjects.$i = $World."$($State.CurrentRoom)".Interactables.$Interactable
        $i++
    }

    # Write the room content to screen.
    Show-Room
    
    # Write extra room options to screen, if any.
    Show-RoomOptions -RoomObjects $RoomObjects

    # Read player action.
    $PlayerInput = Read-Host "What would you like to do?"
    
    # Process player action.
    $ActionMessage = $null
    if (@("N", "E", "S", "W", "U", "D") -contains $PlayerInput) {
        # Process valid moves.
        New-Move -Direction $PlayerInput
    }
    elseif (@(1..9) -contains $PlayerInput -and $PlayerInput -le $RoomObjects.Count) {
        # Process menu actions.
        $ChosenObject = $RoomObjects.[int]$PlayerInput
        if ($ChosenObject.ObjectType -eq "Item") {
            # Remove the item from the room and add it to inventory.
            $ActionMessage = $ChosenObject.ActionMessage
            $World."$($State.CurrentRoom)".Items.Remove($ChosenObject.ItemName)
            $State.Inventory += $ChosenObject.InventoryName
            $ChosenObject = $null
        }
        elseif ($ChosenObject.ObjectType -eq "Interactable") {
            # Process room item.
            $ActionMessage = $ChosenObject.ActionMessage
            $MachineState = "Running"
            while ($MachineState -eq "Running") {
                & "Invoke-$($ChosenObject.InteractableName)"
            }
        }
        else {
            # Fallback to something unexpected.
            Write-Error "Unexpected option chosen. Aborting."
        }
    }

    elseif ($PlayerInput -eq 0) {
        # Show achievement overview.
        Show-Achievements
    }
    elseif ($PlayerInput -eq "help") {
        # Show help overview.
        Show-Help
    }
    elseif ($PlayerInput -eq "Quit") {
        # Exit command.
        $EndScenario = "Default"
        $GameState = "Quit"
    }
    elseif ($PlayerInput -eq "idclip") {
        # Cheat code 
        $State.idclip = $true
        $ActionMessage = "Clipping through doors enabled."
    }
    else {
        # Catch all for invalid input.
        $ActionMessage = "Invalid input, try again."
    }
    
    # Execute game-specific functions.
    Invoke-GameFunctions

    # Check if the game should end because certain conditions are met
    Invoke-EndingCheck
}
#endregion main game.


#########################################
#region ENDING                          #
#########################################

Show-Ending

#endregion ending.