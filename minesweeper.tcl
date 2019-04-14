#!/usr/bin/wish
package require Tk

#global Arrays For Board
global buttonPressed
global isMine
global winOrLoss #-1 = loss, 0 = still playing, 1 = win
global flagged #0 = not flagged, 1= flagged, 2 = ?

global boardWidth
global boardHeight
global numberOfMines
global uncoveredLeft
global minesLeft

#global characters
global mineCharacter
set ::mineCharacter ⋇

#returns button id for given x,y position
proc getButtonID {x y} {
	return x$x-y$y
}

#returns how many mines are around a specific space
proc minesAround {x y} {
	set minesCount 0 
	for {set i [expr $x - 1]} {$i < [expr $x + 2]} {incr i} {
		for {set j [expr $y - 1]} {$j < [expr $y + 2]} {incr j} {
			#check the space exist. It may not if x,y is at an edge		
			if {[info exists ::isMine([getButtonID $i $j])] == 1} {
				if {$::isMine([getButtonID $i $j]) == 1} {
					incr minesCount				
				}
			}
		}
	}
	return $minesCount
}

proc uncoverAllMines {} {
	#uncover all mines
	for {set i 0} {$i < $::boardHeight} {incr i} {
		for {set j 0} {$j < $::boardWidth} {incr j} {
			if {$::buttonPressed([getButtonID $i $j]) == 0 && $::isMine([getButtonID $i $j]) == 1} {
				.board.[getButtonID $i $j] configure -text $::mineCharacter -bd 0 -padx 7
			}	
		}
	}
}

#process to run when you lose like the loser you are
proc loss {} {
	#you LOSE
	set ::winOrLoss -1

	uncoverAllMines
	set answer [tk_messageBox -title "You lost " -type retrycancel -message "Wow, you lost. What a loser." -icon error]
	if {$answer == "retry"} {
		game $::boardHeight $::boardWidth $::numberOfMines
	}
}

#process to run when the player wins
proc win {} {
	#you WIN
	set ::winOrLoss 1

	uncoverAllMines
	set answer [tk_messageBox -title "You win! " -type retrycancel -message "Congradulations! You won!\nPlay again?" -icon warning]
	if {$answer == "retry"} {
		game $::boardHeight $::boardWidth $::numberOfMines
	}
}

#handles what happens when board button is clicked
proc buttonClicked {x y} {

	set buttonID [getButtonID $x $y]
	if {$::buttonPressed($buttonID) == 1 || $::winOrLoss != 0 || $::flagged($buttonID) == 1} {
		return
	}

	#flag that the button was pressed
	set ::buttonPressed($buttonID) 1
	incr ::uncoveredLeft -1

	
	#check if it is a mine
	if {$::isMine($buttonID) == 1} {
		.board.$buttonID configure -relief solid -background white -text $::mineCharacter -state disabled -bd 0 -padx 7 -bg red -fg black
		loss
	} else {
		set numberOfMinesAround [minesAround $x $y]
		if {$numberOfMinesAround == 0} {
			.board.$buttonID configure -relief solid -background white -text "" -state disabled -bd 0 -padx 12
			#click surrounding tiles
			for {set i [expr $x - 1]} {$i < [expr $x + 2]} {incr i} {
				for {set j [expr $y - 1]} {$j < [expr $y + 2]} {incr j} {
					#check the space exist. It may not if x,y is at an edge 
					if {$::buttonPressed($buttonID) == 0} {
						return					
					}	
					if {[info exists ::isMine([getButtonID $i $j])] == 1} {
						if {$::buttonPressed([getButtonID $i $j]) == 0} {
							buttonClicked $i $j		
						}				
					}
				}
			}

		} else {
			.board.$buttonID configure -relief solid -background white -text $numberOfMinesAround -state disabled -bd 0 -padx 7
		}

		#check if player won
		if {$::uncoveredLeft <= 0} {
			win
		}
	}	
	
}

proc rightClick {x y} {
	
	set buttonID [getButtonID $x $y]
	if {$::buttonPressed($buttonID) == 1} {
		return
	}
	
	switch $::flagged($buttonID) {
		0 {
			set ::flagged($buttonID) 1
			.board.$buttonID configure -text "⚑" -padx 5
			incr ::minesLeft -1
		}
		1 {
			set ::flagged($buttonID) 2
			.board.$buttonID configure -text "?" -padx 7
			incr ::minesLeft
		}
		default {
			set ::flagged($buttonID) 0
			.board.$buttonID configure -text " " -padx 8
		}
	}
}

proc randomLocation {height width} {
	return [getButtonID [expr int([expr rand() * $height])] [expr int([expr rand() * $width])]]
}

proc initializeMines {height width numberOfMines} {
	for {set i 0} {$i < $numberOfMines} {} {
		set newMine [randomLocation $height $width]
		if {$::isMine($newMine) == 0} {
			set ::isMine($newMine) 1
			#.board.$newMine configure -text $::mineCharacter -padx 6
			incr i
		}
	}
}

#~~~~~~~~~~~~~~~~~~~~~~MAIN~~~~~~~~~~~~~~~
proc game {height width numberOfMines} {
	
	#0 = ongoing game
	#1 = win
	#-1 = loss
	set ::winOrLoss 0

	#setup board
	destroy .board	
	frame .board -padx 5 -pady 5 -background white
	pack .board -fill both -expand 1

	#initialize buttons
	for {set i 0} {$i < $height} {incr i} {
		for {set j 0} {$j < $width} {incr j} {
			set ::buttonPressed([getButtonID $i $j]) 0
			set ::isMine([getButtonID $i $j]) 0
			set ::flagged([getButtonID $i $j]) 0
			button .board.[getButtonID $i $j] -width 0 -height 0 -command [list buttonClicked $i $j]
			bind .board.[getButtonID $i $j] <ButtonPress-3> [list rightClick $i $j]
			grid .board.x$i-y$j -row $i -column $j
		}
	}

	#initalize mines
	initializeMines $height $width $numberOfMines
	set ::minesLeft $numberOfMines
	set ::uncoveredLeft [expr ($height * $width) - $numberOfMines]

	#setup score
	destroy .score
	frame .score -padx 5 -pady 5
	pack .score -fill both -expand 1

	label .score.tilesLeftLabel -text "Safe tiles left: "
	grid .score.tilesLeftLabel -row 0 -column 0
	label .score.tilesLeft -text "$::uncoveredLeft" -textvariable ::uncoveredLeft
	grid .score.tilesLeft -row 0 -column 1 
	label .score.minesLeftLabel -text "   Mines left: "
	grid .score.minesLeftLabel -row 0 -column 2
	label .score.minesLeft -text "$::minesLeft" -textvariable ::minesLeft
	grid .score.minesLeft -row 0 -column 3
}

#~~~~~~~~~~~~~~~~~~~FLOW OF CONTROL STARTS HERE~~~~~~~~~~~~~~~~~~~~~~~~~~~~~`
#checks that the correct number of commandline arguments were input
#args are board height, board width, and number of Mines
if { $argc != 3 } {
	puts "Incorrect number of commandline arguments"
	puts "Please input height, width, and number of mines."
	puts "Defaulting to 10x10 with 10 mines"
	set ::boardHeight 10
	set ::boardWidth 10
	set ::numberOfMines 10	
} else {
	set ::boardHeight [lindex $argv 0]
	set ::boardWidth [lindex $argv 1]
	set ::numberOfMines [lindex $argv 2]

	if {[expr $::boardHeight * $::boardWidth] <= $::numberOfMines} {
		puts "There are too many mines! I guess we'll decide that for you"	
		set numberOfMines [expr int([expr $::boardHeight * $::boardWidth / 10])]
	}	
}

wm title . "TCL-TK Minesweeper" 
wm geometry . +300+300

menu .menuBar
. configure -menu .menuBar
menu .menuBar.game -tearoff 0
.menuBar add cascade -menu .menuBar.game -label Game -underline 0
.menuBar.game add command -label "New Game" -command {game $::boardHeight $::boardWidth $::numberOfMines}
.menuBar.game add command -label "Exit" -command {exit}


game $::boardHeight $::boardWidth $::numberOfMines
