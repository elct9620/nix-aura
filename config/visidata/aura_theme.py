'''Terminal-palette theme: colors come from the terminal's default fg/bg and
its 16 ANSI colors, so VisiData follows whatever theme the terminal uses
instead of the built-in fixed black background and xterm-256 shades.'''

from visidata import vd

vd.themes['terminal'] = dict(
        color_default         = '',
        color_default_hdr     = 'bold',
        color_bottom_hdr      = 'underline',
        color_column_sep      = '',
        color_current_col     = 'bold',
        color_key_col         = 'cyan',
        color_selected_row    = 'yellow',
        color_note_row        = 'yellow',
        color_note_type       = 'yellow',
        color_error           = 'red',
        color_warning         = 'yellow',
        color_working         = 'green',
        color_status          = 'bold on black',
        color_active_status   = 'bold white on blue',
        color_inactive_status = 'on black',
        color_keystrokes      = 'bold white on black',
        color_longname_guide  = '',
        color_code            = 'bold white on black',
        color_guide_unwritten = '',
        color_menu            = 'white on blue',
        color_menu_active     = 'bold yellow',
        color_menu_spec       = 'white on green',
        color_menu_help       = 'italic white on blue',
        color_sidebar         = 'white on blue',
        color_cmdpalette      = 'on black',
        color_aggregator      = 'bold on black',
        color_edit_cell       = 'reverse',
        color_edit_unfocused  = 'on black',
        color_graph_hidden    = 'blue',
        color_git_untracked   = 'blue',
        color_git_unstaged_del = 'on red',
        plot_colors           = 'green red yellow cyan magenta blue white',
)

# Default only; ~/.visidatarc loads afterwards and may pick another theme.
vd.options.theme = 'terminal'
