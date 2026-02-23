# Center prompt on empty Enter key press
# DOES NOT WORK IN WARP TERMINAL

# Load terminfo modules to make the associative array $terminfo available
zmodload zsh/terminfo

# Save current prompt to parameter PS1o
PS1o="$PS1"

# Calculate how many lines one half of the terminal's height has
halfpage=$((LINES/2))

# Construct parameter to go down/up $halfpage lines via termcap
halfpage_down=""
for i in {1..$halfpage}; do
  halfpage_down="$halfpage_down$terminfo[cud1]"
done

halfpage_up=""
for i in {1..$halfpage}; do
  halfpage_up="$halfpage_up$terminfo[cuu1]"
done

# Define functions
function prompt_middle() {
  PS1="%{${halfpage_down}${halfpage_up}%}$PS1o"
}

function prompt_restore() {
  PS1="$PS1o"
}

# magic-enter: move prompt to middle of terminal on empty enter
magic-enter () {
    if [[ -z $BUFFER ]]
    then
            print ${halfpage_down}${halfpage_up}$terminfo[cuu1]
            zle reset-prompt
    else
            zle accept-line
    fi
}
zle -N magic-enter
bindkey "^M" magic-enter
