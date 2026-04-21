Based on the tmux configuration by gpakosz: https://github.com/gpakosz/.tmux

Install via the repo-root `install.sh`, which symlinks `.tmux.conf` and
`.tmux.conf.local` into `$HOME` and clones TPM into `~/.tmux/plugins/tpm`.

After starting tmux for the first time, install the plugins with:

    prefix + I    (i.e. C-q I)

Personal customizations (prefix `C-q`, pane bindings, etc.) live in
`.tmux.conf.local` under the `-- user customizations --` section.
