#Here's to hoping you use monospace fonts in your MIPS editor
#    ___                           _   _           
#   /   \__ _ _ __     /\/\   ___ | |_| | ___  ___ 
#  / /\ / _` | '_ \   /    \ / _ \| __| |/ _ \/ __|
# / /_// (_| | | | | / /\/\ \ (_) | |_| |  __/\__ \
#/___,' \__,_|_| |_| \/    \/\___/ \__|_|\___||___/
#		Dan Motles
#       seltom.dan@gmail.com
# for use with MARS http://courses.missouristate.edu/kenvollmar/mars/download.htm
#=======Project #1=======
# This is a little game that picks a word from a word
# bank, scrambles it randomly, and asks you to guess
# it's letters until you run out of guesses. Plays a lot
# like wheel of fortune crossed with Hangman

.data
### WORD BANK ###
WORD0:		.asciiz	"computer"
WORD1:		.asciiz	"processor"
WORD2:		.asciiz	"motherboard"
WORD3:		.asciiz	"graphics"
WORD4:		.asciiz "network"
WORD5:		.asciiz "ethernet"
WORD6:		.asciiz "memory"
WORD7:		.asciiz "microsoft"
WORD8:		.asciiz	"linux"
WORD9:		.asciiz	"transistor"
WORD10:		.asciiz	"antidisestablishmentarianism"
WORD11:		.asciiz "protocol"
WORD12:		.asciiz "instruction"

WORDS:		.word	WORD0, WORD1, WORD2, WORD3, WORD4, WORD5, WORD6, WORD7, WORD8, WORD9, WORD10, WORD11, WORD12

WORDS_LENGTH:	.word	13
#################

#permuted word
PERMUTED_WORD:	.space	32

#guessed letters word
GUESSED:	.space	32

#String Table
WELCOME:	.asciiz "Welcome to Scramble (C) Dan Motles 2011!\n"
IM_THINKING:	.asciiz "I'm thinking of a word. "
YES:		.asciiz "Yes! "
NO:		.asciiz "No! "
THE_WORD_IS:	.asciiz "The word is "
SCORE_IS:	.asciiz ". Score is "
GUESS_A_LETTER: .asciiz	"Guess a letter?\n"
FORFEIT:	.asciiz "-WORD FORFIETED- "
NO_POINTS:	.asciiz "You earned 0 points that round.\n"
ROUND_OVER:	.asciiz "Round is over. Your final guess was:\n"
CORRECT_WORD:	.asciiz "\nCorrect unscrambled word was:\n"
.:		.asciiz ".\n"
PLAY_AGAIN:	.asciiz "Do you want to play again (y/n)?\n"
FINAL_SCORE_IS:	.asciiz "Your final score is "
ITSBEENFUN:	.asciiz ". It's Been Fun!\n"
NL:		.asciiz "\n"
GOODBYE: .byte   0x2e, 0x20, 0x47, 0x6f, 0x6f, 0x64, 0x62, 0x79, 0x65, 0x21, 0x0a, 0x54, 0x68, 0x69, 0x73, 0x20, 0x70, 0x72, 0x6f, 0x67, 0x72, 0x61, 0x6d, 0x20, 0x69, 0x73, 0x20, 0x66, 0x72, 0x6f, 0x6d, 0x20, 0x68, 0x74, 0x74, 0x70, 0x3a, 0x2f, 0x2f, 0x67, 0x69, 0x74, 0x68, 0x75, 0x62, 0x2e, 0x63, 0x6f, 0x6d, 0x2f, 0x64, 0x6d, 0x6f, 0x74, 0x6c, 0x65, 0x73, 0x0a, 0x00
.text
#-----------------------------------------------------------------------------\
#	main()
#	The main program
#-----------------------------------------------------------------------------/
main:
	jal 	seed_rand			# seed random function
	lw	$s0, WORDS			# Initialize s0 with the first word
	and	$s1, $s1, $0			# initialize s1 to 0 (s1 == player score)
	and	$s2, $s2, $0			# initialize s2 to 0 (s2 == run counter)
	
	#print welcome
	la	$a0, WELCOME
	jal	print
	
	# While the user hasn't wanted to quit
_game_loop:
	#if run_counter == 0, skip rand word
	beq	$s2, $0, _if_not_rand		# branch if the run counter is 0
	
	jal	get_rand_word			#get a new random word
	move	$s0, $v0			#move to print
	
_if_not_rand:
	la	$a0, IM_THINKING
	jal	print				# print "I'm thinking of a word"
	
	#Permute!
	la	$a0, PERMUTED_WORD		# get buffer to store permuted word
	move	$a1, $s0			# get the original word
	jal	permute				# permute!
	
	#play game
	jal	play_round			# plays a round
	
	#increment stuffs
	add	$s1, $s1, $v0			# add return value of play_round to player score
	addi	$s2, $s2, 1
	
	#output post-round info
	la	$a0, CORRECT_WORD		#load string address into correct register
	jal	print				#print "the correct word was:"
	move	$a0, $s0			#load unscrambled word into right arg register
	jal	print				#print the unscrambled word
	la	$a0, NL
	jal	print				# print newline
	
_main_prompt_char:
	la	$a0, PLAY_AGAIN			#load the "play again?" string
	jal	print				#print the "play again?" string
	jal	prompt_char			#prompt for a character
	
	beq	$v0, 121, _game_loop		# if prompted char is == 'y', return to game loop (play again)
	bne	$v0, 110, _main_prompt_char	# if we didn't get an 'n' either, branch up to prompt again.
	
	# Final Score is...
	la	$a0, FINAL_SCORE_IS		# load final score is string
	jal	print				# print final score is
	
	#print num
	move	$a0, $s1			# move player score in place to be printed
	jal	print_int
	
	#goodbye!
    la  $a0, GOODBYE           # say goodbye
    jal print                   # print goodbye
	
	
exit:	li	$v0, 10
	syscall
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ END MAIN ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


#-----------------------------------------------------------------------------\
#	seed_rand()
#	Seeds the random number generator with time.
#-----------------------------------------------------------------------------/
seed_rand:
	## Prologoue ##
	addi	$sp, $sp, -8				#allocate 8 bytes
	sw	$a0, 0($sp)				#store a0 in stack
	sw	$a1, 4($sp)				#store a1 in stack
	## Code ##
	
	addi	$v0, $0, 30				#30 = get time syscall
	syscall
	
	move	$a1, $a0				# use the low ordered time bits.
	addi 	$v0, $0, 40				# 40 = set seed
	and 	$a0, $a0, $0				# set a0 to 0
	syscall
	
	## Epilogue ##
	lw	$a1, 4($sp)				#put back old a1
	lw	$a0, 0($sp)				#put back old a0
	addi	$sp, $sp, 8				#deallocate
	jr	$ra				#return
#~~~~~~~~~~~~~~~~~~~~~~~~~~ END SEED_RAND ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


#-----------------------------------------------------------------------------\
#	get_rand_word()
#	Returns the address of a random word in the words array
#	
#	$v0 = Returns the address of a random word
#-----------------------------------------------------------------------------/
get_rand_word:
	## Prologue ##
	addi	$sp, $sp, -8			# allocate 12 bytes on stack
	sw	$a0, 0($sp)			# store a0
	sw	$a1, 4($sp)			# store a1
	
	## Code ##
	addi 	$v0, $0, 42				# 42 = rand int range syscall
	and 	$a0, $a0, $0				# set a0 to 0
	lw	$a1, WORDS_LENGTH			# set a1 to WORDS_LENGTH
	syscall						# a0 now contains a rand int within WORDS_LENGTH
	
	mul	$a0, $a0, 4				# since words are 4 bytes the rand number needs to be X4
	lw	$v0, WORDS($a0)				# get word address stored in t0
	
	## Epilogue ##
	lw	$a1, 4($sp)			#reload old a1
	lw	$a0, 0($sp)			#reload old a0
	addi	$sp, $sp, 8			#deallocate
	jr	$ra				#return
#~~~~~~~~~~~~~~~~~~~~~~~~~~ END GET_RAND_WORD ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


#-----------------------------------------------------------------------------\
#	get_rand(max)
#	Returns a random int between 0<=x<=max
#	
#	$v0 = the random int within range
#-----------------------------------------------------------------------------/
get_rand:
	## Prologue ##
	addi	$sp, $sp, -8			# allocate 12 bytes on stack
	sw	$a0, 0($sp)			# store a0
	sw	$a1, 4($sp)			# store a1
	
	## Code ##
	addi 	$v0, $0, 42				# 42 = rand int range syscall
	move	$a1, $a0				# move range to correct register
	and 	$a0, $a0, $0				# set a0 to 0
	syscall						# a0 now contains a rand int within a1 range
	
	move	$v0, $a0
	
	## Epilogue ##
	lw	$a1, 4($sp)
	lw	$a0, 0($sp)
	addi	$sp, $sp, 8			#deallocate
	jr	$ra				#return
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ END GET_RAND ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


#-----------------------------------------------------------------------------\
#	permute(dest, source)
#	premutes the source string into the destination string
#	$a0 = destination
#	$a1 = source
#-----------------------------------------------------------------------------/
permute:
	## Prologue ##
	addi	$sp, $sp, -28			#allocate 28 bytes of space
	sw	$ra, 0($sp)			#save return address
	sw	$a0, 4($sp)			#save old a0
	sw	$a1, 8($sp)			#save old a1
	sw	$s0, 12($sp)			#save old s0
	sw	$s1, 16($sp)			#save old s1
	sw	$s2, 20($sp)			#save old s2
	sw	$s7, 24($sp)			#save old s7
	
	## Code ##
	move	$s0, $a0			# s0 = DESTINATION
	move	$s1, $a1			# s1 = SOURCE
	
	jal	strcpy				#copy source string to destination
	jal	strlen				#get it's length
	
	move	$s2, $v0			# s2 = string length
	addi	$s7, $s2, -1			# set [i]terator (s7) = len-1
_permute_loop:
	# while i < 2
	beq	$s7, 1, _permute_loop_end
	
	#get random of the remaining set of indexes
	move	$a0, $s7			# get_rand( i )
	jal	get_rand
	
	#swap value returned from get_rand and i, the current index
	move	$a0, $s0			# the array we are swapping
	move	$a1, $s7			# current value of i, iterator
	move	$a2, $v0			# the random index
	jal	swap
	
	addi	$s7, $s7, -1			# subtract 1 from iterator
	j	_permute_loop			# go back to beginning of loop
	
_permute_loop_end:	
	## Epilogue ##
	lw	$ra, 0($sp)			#load return address
	lw	$a0, 4($sp)			#load old a0
	lw	$a1, 8($sp)			#load old a1
	lw	$s0, 12($sp)			#load old s0
	lw	$s1, 16($sp)			#load old s1
	lw	$s2, 20($sp)			#load old s2
	lw	$s7, 24($sp)			#load old s7
	addi	$sp, $sp, -28			#deallocate
	jr	$ra				#return
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ END PERMUTE ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


#-----------------------------------------------------------------------------\
#	swap(string, index1, index2)
#	Swaps index1 and index2 in string
#	$a0 = string
#	$a1 = index1
#	$a2 = index2
#	
#-----------------------------------------------------------------------------/
swap:	
	## Code ##
	#grab first index char
	add	$t0, $a0, $a1			#get address of string[index1]
	lb	$t1, 0($t0)			#t1 = string[index1]
	
	#grab second index char
	add	$t0, $a0, $a2			#get address of string[index2]
	lb	$t2, 0($t0)			#t2 = string[index2]
	
	#put first index char in right place
	#(t0 still pointing to index2's location)
	sb	$t1, 0($t0)			#store index1 into index2's old location
	
	#put second index char in right place
	add	$t0, $a0, $a1			#get address of string[index1]
	sb	$t2, 0($t0)			#store index2 into index1's old location
	
	
	## Prologue ##
	jr	$ra				#return
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ END SWAP ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~



#-----------------------------------------------------------------------------\
#	strlen(string)
#	gets length of string
#	$a0 = string
#	
#	$v0 = Returns num chars copied
#-----------------------------------------------------------------------------/
strlen:
	## Prologue ##
	addi	$sp, $sp, -4			#allocate 4 bytes
	sw	$a0, 0($sp)			# store current a0
	
	## Code ##
	and	$v0, $v0, $0			# set iterator to 0
_length_loop:
	lb	$t8, 0($a0)			# get the byte from the string	
	beq	$t8, $0, _length_loop_end		# If nul, quit loop
	
	addi	$a0, $a0, 1			# increment dest address
	addi	$v0, $v0, 1			# increment count
	
	j	_length_loop			# jump to top of loop

_length_loop_end:	
	## Epilogue ##
	lw	$a0, 0($sp)			#load old a0
	addi	$sp, $sp, 4			#deallocate
	jr	$ra				#return
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ END STRLEN ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


#-----------------------------------------------------------------------------\
#	strcpy(dest, source)
#	Copies source string into destination
#	$a0 = dest
#	$a1 = source
#	
#	$v0 = Returns num chars copied
#-----------------------------------------------------------------------------/
strcpy:
	## Prologue ##
	addi	$sp, $sp, -8			# allocate 8 bytes
	sw	$a0, 0($sp)			# store current a0
	sw	$a1, 4($sp)			# store current a1
	
	## Code ##
	and	$v0, $v0, $0			# set iterator to 0
_copy_loop:
	lb	$t8, 0($a1)			# get the byte from the source string	
	sb	$t8, 0($a0)			# store byte into dest string
	beq	$t8, $0, _copy_loop_end		# If nul, quit loop
		
	addi	$a0, $a0, 1			# increment dest address
	addi	$a1, $a1, 1			# increment source address
	addi	$v0, $v0, 1			# increment count

	j	_copy_loop			# jump to top of loop
_copy_loop_end:	
	## Epilogue ##
	lw	$a0, 0($sp)			# load old a0
	lw	$a1, 4($sp)			# load old a1
	addi	$sp, $sp, 8			# deallocate
	jr	$ra				#return
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ END STRCPY ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


#-----------------------------------------------------------------------------\
#	play_round(string)
#	Plays game round with string
#	$a0 = string
#	
#	$v0 = Returns round score
#-----------------------------------------------------------------------------/
play_round:
	## Prologue ##
	addi	$sp, $sp, -24			# allocate 12 bytes
	sw	$ra, 0($sp)			# save return address
	sw	$a0, 4($sp)			# store current a0
	sw	$a1, 8($sp)			# store current a1
	sw	$s0, 12($sp)			# store current s0
	sw	$s1, 16($sp)			# store current s1
	sw	$s2, 20($sp)			# store current s2
	
	## Code ##
	jal	strlen				# get length
	move	$s0, $v0			# store length (score) in s0
	move	$s1, $a0			# save the string location
	
	#setup the underscores
	la	$a0, GUESSED			# get the guessed word buffer
	move	$a1, $s0			# get the word length
	jal	fill_blanks			# fill the word with underscores
	
_round_loop:
	# DO WHILE score > 0 && underscores_present
	beq	$s0, $0, _round_loop_end	# Sanity check
		
	#	_STATUS DISPLAY_
	la	$a0, THE_WORD_IS		# print "The word is ___"
	jal	print
	la	$a0, GUESSED			# print the guessed word so far
	jal	print
	la	$a0, SCORE_IS			# print score is
	jal	print
	move	$a0, $s0			# print actual score
	jal	print_int
	la	$a0, .				# print period
	jal	print
	
	#output guess a letter prompt
	la	$a0, GUESS_A_LETTER		
	jal	print				# prints "Guess a letter?"
	
	#prompt for char
	jal	prompt_char			# prompt for character
	move	$s2, $v0			# save character entered in v0
	
	beq	$s2, 46, _round_forfeit		# if '.' is entered, end round
	
	#see if string contains char
	move	$a0, $s1			# move s1 (the location of the original word) into a0
	move	$a1, $s2			# move the char entered in a1
	jal	str_contains			# see if string contains character
	
	# if string does not contain the char, print NO, else print YES and update our guessed word.
	bne	$v0, $0, _round_char_found	# if return value != 0, we have success
	
	### IF Char match not found
	addi	$s0, $s0 -1			# wrong char, subtract 1 from score
	
	# character not found. Display NO!
	la	$a0, NO				# load NO!
	jal	print				# print NO!
	beq	$s0, $0, _round_no_points	# if score == 0, end round NOW
	
	j	_round_loop			# Guess again!
_round_char_found:
	#char found, print YES and update GUESSED
	
	# update GUESSED
	la	$a0, GUESSED			# load address of GUESSED buffer
	move	$a1, $s1			# load address of the permuted word
	move	$a2, $s2			# load the character the player just entered
	jal	update_guessed			# updated the GUESSED buffer with correct letters
	
	# if the GUESSED buffer contains underscores '_', continue
	la	$a0, GUESSED			# load GUESSED address for strcontains
	addi	$a1, $0, 95			# set a1 (the char) to 95 (the ascii value of underscore) for strcontains
	jal	str_contains			# check if GUESSED still has underscores
	beq	$v0, $0, _round_loop_end	# if no underscores left in guess, end round
	
	#print yes
	la	$a0, YES			# load Yes!
	jal	print				# print Yes!

	j	_round_loop			# jump to top of loop
_round_forfeit:
	la	$a0, FORFEIT			# load forfeit message
	jal	print				# print forfeit message
	and	$s0, $s0, $0			# forfeit round? NO SCORE.
_round_no_points:
	la	$a0, NO_POINTS			# load the you earned no points
	jal	print				# print you earned no points
_round_loop_end:

	# End of round msg
	la	$a0, ROUND_OVER			# Display round over message
	jal	print
	la	$a0, GUESSED			# Display letters guessed
	jal	print
	
	move	$v0, $s0			# move s0 (score) to v0 (return register)
		
	## Epilogue ##
	lw	$ra, 0($sp)			# load return address
	lw	$a0, 4($sp)			# load old a0
	lw	$a1, 8($sp)			# load old a1
	lw	$s0, 12($sp)			# load old s0
	lw	$s1, 16($sp)			# load old s1
	lw	$s2, 20($sp)			# load old s2
	addi	$sp, $sp, 24			# deallocate
	jr	$ra				#return
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ END PLAY_ROUND ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


#-----------------------------------------------------------------------------\
#	fill_blanks(string, num)
#	Places num underscores into string
#	$a0 = string
#	$a1 = num underscores
#-----------------------------------------------------------------------------/
fill_blanks:
	## Prologue ##
	addi	$sp, $sp, -8			# allocate 8 bytes
	sw	$a0, 0($sp)			# store current a0
	sw	$a1, 4($sp)			# store current a1
	
	## Code ##
	add	$a0, $a0, $a1			# a0 = address of string + length
	addi	$t1, $0, 95			# set t1 = ascii value for '_' underscore
	sb	$0,0($a0)			# set last byte to nul
_fill_blanks_loop:
	beq	$a1, $0, _fill_blanks_loop_end	# if a1 < 0, we're done.
	addi	$a0, $a0, -1			# decrement buffer position
	addi	$a1, $a1, -1			# decrement length
	sb	$t1, 0($a0)			# store underscore
	j	_fill_blanks_loop		# back to start of loop
_fill_blanks_loop_end:
	## Epilogue ##
	lw	$a0, 0($sp)			# load old a0
	lw	$a1, 4($sp)			# load old a1
	addi	$sp, $sp, 8			# deallocate
	jr	$ra				#return
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ END FILL_BLANKS ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


#-----------------------------------------------------------------------------\
#	prompt_char()
#	Prompts for a character
#-----------------------------------------------------------------------------/
prompt_char:
	## Prologue ##
	addi	$sp, $sp, -12			# allocate 4 bytes
	sw	$ra, 0($sp)			# store old return address
	sw	$a0, 4($sp)			# store old a0
	sw	$s0, 8($sp)			# store old s0
	## Code ##

	addi $v0, $0, 12			# 4 = print string syscall
	syscall					# v0 now contains a char
	move	$s0, $v0			# temporarily save char
	
	la	$a0, NL
	jal	print				#print newline
	jal	print				#print newline
	
	move	$v0, $s0			# move char back into return register
	
	## Epilogue ##
	lw	$ra, 0($sp)			# load old return address
	lw	$a0, 4($sp)			# load old a0
	lw	$s0, 8($sp)			# load old s0
	addi	$sp, $sp, 12			# deallocate
	jr	$ra				#return
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ END PPROMPT_CHAR ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#-----------------------------------------------------------------------------\
#	str_contains(string, char)
#	Checks to see if a string contains a given character
#	$a0 = string
#	$a1 = char
#
#	Returns 0 if not found, 1 if found
#-----------------------------------------------------------------------------/
str_contains:
	## Prologue ##
	addi	$sp, $sp, -4			# allocate 4 bytes
	sw	$a0, 0($sp)			# store old a0
	
	## Code ##
	and	$v0, $v0, $0			# set $v0 to 0 or FALSE
	
_str_contains_loop:
	lb	$t0, 0($a0)				# load char in from string
	beq	$t0, $0, _str_contains_loop_end		#if we reach end of string, stop loop
	beq	$t0, $a1, _char_found			#if char matches the passed in value, branch
	addi	$a0, $a0, 1				# increment string address to continue scanning
	j	_str_contains_loop			# jump to top of loop
_char_found:
	addi	$v0, $0, 1				# if char found, set return value = 1
_str_contains_loop_end:
	## Epilogue ##
	lw	$a0, 0($sp)			# load old a0
	addi	$sp, $sp, 4			# deallocate
	jr	$ra				#return
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ END STR_CONTAINS ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#-----------------------------------------------------------------------------\
#	update_guessed(guessed, orig, char)
#	Will update the guessed word buffer with correctly guessed letters
#	$a0 = guessed buffer
#	$a1 = original string
#	$a2 = char
#-----------------------------------------------------------------------------/
update_guessed:
	## Prologue ##
	addi	$sp, $sp, -8			# allocate 4 bytes
	sw	$a0, 0($sp)			# store old a0
	sw	$a1, 4($sp)			# store old a1
	
	## Code ##
_update_g_loop:
	lb	$t0, 0($a1)				# load char in from string
	beq	$t0, $0, _update_g_loop_end		#if we reach end of string, stop loop
	bne	$t0, $a2, _char_not_found		#if char doesn't match, branch
	sb	$a2, 0($a0)				# store passed in char in desired position.
_char_not_found:
	addi	$a0, $a0, 1				#increment guessed buffer
	addi	$a1, $a1, 1				#increment original string pos
	j	_update_g_loop
_update_g_loop_end:
	## Epilogue ##
	lw	$a1, 4($sp)			# load old a1
	lw	$a0, 0($sp)			# load old a0
	addi	$sp, $sp, 8			# deallocate
	jr	$ra				# return
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ END UPDATE_GUESSED ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


#-----------------------------------------------------------------------------\
#	print( string )
#	Prints the null terminated string at passed address
#	
#	$a0 = Address of string to print
#-----------------------------------------------------------------------------/
print:
	## Code ##
	addi $v0, $0, 4				# 4 = print string syscall
	syscall
	
	## Epilogue ##
	jr	$ra				#return
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ END PRINT ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


#-----------------------------------------------------------------------------\
#	print_int( int )
#	Prints an int
#	
#	$a0 = Int to print
#-----------------------------------------------------------------------------/
print_int:
	## Code ##
	addi $v0, $0, 1				# 1 = print int syscall
	syscall
	
	## Epilogue ##
	jr	$ra				#return
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ END PRINT_INT ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
