atom-shell-haxelib
===================

Haxelib which downloads atom-shell binary for your platform and makes it accessible via `haxelib run atom-shell path/to/index.html`

### Installation using haxelib
``` bash
haxelib install atom-shell
```

### Using version from github:
``` bash
haxelib git atom-shell https://github.com/as3boyan/atom-shell-haxelib
```

### How to use:
`haxelib run atom-shell path/to/index.html`
is equvalent to
`atom path/to/index.html`


NOTE: Currently tested only on Linux.

On first use it should automatically download latest version of atom-shell.

### Autoupdate system
atom-shell-haxelib should check latest version for atom-shell binary automatically each 7 days. It checks for updates when you run it.

You can disable/enable autoupdate system(enabled by default) using these command line arguments
`haxelib run atom-shell autoupdate false`
Disables autoupdate system.
`haxelib run atom-shell autoupdate true`
Enables autoupdate system.

### How to update atom-shell binary
Also you can manually update atom-shell binary to the latest version using this command:
`haxelib run atom-shell setup`

### How it works:

atom-shell-haxelib heavily uses many helpers and classes from lime-tools(https://github.com/openfl/lime-tools)
