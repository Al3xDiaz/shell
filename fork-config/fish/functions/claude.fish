function claude --wraps claude --description 'Run claude with the caelestia idle inhibitor on, so the screen does not lock mid-session'
    set -l was_enabled (qs -c caelestia ipc call idleInhibitor isEnabled 2>/dev/null)

    if test "$was_enabled" != "true"
        qs -c caelestia ipc call idleInhibitor enable 2>/dev/null
    end

    command claude $argv
    set -l exit_code $status

    if test "$was_enabled" != "true"
        qs -c caelestia ipc call idleInhibitor disable 2>/dev/null
    end

    return $exit_code
end
