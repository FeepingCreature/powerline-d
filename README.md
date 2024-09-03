# Notice: AI-Generated Software

This port was created nearly entirely by Claude 3.5 Sonnet. Warning: many workflows from powerline-shell have been
ported, but I have not tested them.

It works on my system and for my uses. Otherwise, **caveat emptor.**

# Powerline-D: A Powerline style prompt for your shell

Powerline-D is a D port of the popular [powerline-shell](https://github.com/b-ryan/powerline-shell) project. It provides a beautiful and useful prompt generator for Bash, ZSH, Fish, and tcsh:

- Shows important details about the git/svn/hg/fossil branch
- Changes color if the last command exited with a failure code
- Shortens the displayed path with an ellipsis if you're too deep into a directory tree
- Shows the current Python virtualenv environment
- Easy to customize and extend

## Features

### Version Control

Powerline-D supports various version control systems, providing a quick look into the state of your repo:

- Displays the current branch and changes background color when the branch is dirty
- Shows the difference in number of commits between local and remote branches
- Summarizes modified, staged, untracked, and conflicted files with symbols

### Customization

Powerline-D is highly customizable through a JSON configuration file, allowing you to:

- Add, remove, and rearrange segments
- Choose from different themes or create your own
- Configure individual segments

## Setup

1. Install the D compiler (DMD, LDC, or GDC)
2. Clone the Powerline-D repository:
   ```
   git clone https://github.com/FeepingCreature/powerline-d.git
   cd powerline-d
   ```
3. Build the project:
   ```
   dub build
   ```
4. Add the built executable to your PATH
5. Set up your shell prompt using the instructions for your shell below

### Bash

Add the following to your `.bashrc` file:

```bash
function _update_ps1() {
    PS1=$(powerline-d --shell bash $?)
}

if [[ $TERM != linux && ! $PROMPT_COMMAND =~ _update_ps1 ]]; then
    PROMPT_COMMAND="_update_ps1; $PROMPT_COMMAND"
fi
```

### ZSH

Add the following to your `.zshrc`:

```zsh
function powerline_precmd() {
    PS1="$(powerline-d --shell zsh $?)"
}

function install_powerline_precmd() {
  for s in "${precmd_functions[@]}"; do
    if [ "$s" = "powerline_precmd" ]; then
      return
    fi
  done
  precmd_functions+=(powerline_precmd)
}

if [ "$TERM" != "linux" -a -x "$(command -v powerline-d)" ]; then
    install_powerline_precmd
fi
```

### Fish

Redefine `fish_prompt` in `~/.config/fish/config.fish`:

```fish
function fish_prompt
    powerline-d --shell fish $status
end
```

### tcsh

Add the following to your `.tcshrc`:

```tcsh
alias precmd 'set prompt="`powerline-d --shell tcsh $?`"'
```

## Configuration

Powerline-D uses a JSON configuration file. The default locations for this file are:

1. `powerline-d.json` in the current directory
2. `~/.powerline-d.json`

If no configuration file is found, Powerline-D will use default settings.

### Example Configuration

Here's an example of a `powerline-d.json` configuration file:

```json
{
    "segments": [
        "ssh",
        {
            "type": "cwd",
            "mode": "fancy",
            "max_depth": 4
        },
        "git",
        "hg",
        "jobs",
        "root"
    ],
    "mode": "patched",
    "theme": "default"
}
```

### Main Configuration

The main configuration file structure is as follows:

- `segments`: An array of segment names or objects defining which segments to display and in what order.
- `mode`: Can be "patched" (for Powerline fonts) or "compatible" (for standard fonts).
- `theme`: The name of the theme to use.

### Themes

Themes are JSON files that define colors for different parts of the prompt. They can be placed in:

1. `~/.powerline-themes/theme_name.json`
2. `themes/theme_name.json` in the Powerline-D installation directory

Here's an example theme file structure:

```json
{
    "usernameFg": 250,
    "usernameBg": 240,
    "usernameRootBg": 124,
    "hostnameFg": 250,
    "hostnameBg": 238,
    "homeSpecialDisplay": true,
    "homeBg": 31,
    "homeFg": 15,
    "pathBg": 237,
    "pathFg": 250,
    "cwdFg": 254,
    "separatorFg": 244,
    "readonlyBg": 124,
    "readonlyFg": 254,
    "sshBg": 166,
    "sshFg": 254,
    "repoCleanBg": 148,
    "repoCleanFg": 0,
    "repoDirtyBg": 161,
    "repoDirtyFg": 15,
    "jobsFg": 39,
    "jobsBg": 238,
    "cmdPassedBg": 236,
    "cmdPassedFg": 15,
    "cmdFailedBg": 161,
    "cmdFailedFg": 15
}
```

## Customization

You can customize individual segments by replacing the segment name in the `segments` array with an object:

```json
{
    "segments": [
        "ssh",
        {
            "type": "cwd",
            "mode": "plain",
            "max_depth": 4
        },
        "git",
        "jobs",
        "root"
    ],
    "mode": "patched",
    "theme": "default"
}
```

Each segment type has its own set of configuration options. Here are some common segments and their options:

- `cwd`:
  - `mode`: "plain" or "fancy"
  - `max_depth`: Maximum directory depth to display
- `git`:
  - `show_symbol`: Boolean to show/hide the Git symbol
- `hostname`:
  - `colorize`: Boolean to enable/disable hostname colorization

Refer to the source code for specific segment options and their default values.

## Contributing

Contributions to Powerline-D are welcome! Please submit pull requests with new features, bug fixes, or improvements.

## Troubleshooting

If you encounter problems, please open an [issue](https://github.com/FeepingCreature/powerline-d/issues/new).

## Credits

Powerline-D is a D port of [powerline-shell](https://github.com/b-ryan/powerline-shell) by [b-ryan](https://github.com/b-ryan). The port was created by Claude 3.5 Sonnet.

## License

Powerline-D is released under the MIT License. See the [LICENSE](LICENSE) file for details.
