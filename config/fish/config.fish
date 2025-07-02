if status is-interactive
    # Commands to run in interactive sessions can go here
end

if type -q tmux
	if not test -n "$TMUX"
		tmux attach-session -t default; or tmux new-session -s default
	end
end

set -g fish_greeting ""

fish_add_path ~/.local/bin

bind ctrl-f ~/.local/scripts/sessionizer

bind ctrl-s ~/.local/scripts/scripter

/home/davi/.local/bin/mise activate fish | source
