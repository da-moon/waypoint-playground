# overview

waypoint configuration file is a single `waypoint.hcl` file in project's root.

`project` directive is used to set project name and every deployable application has it's own  `app` stanza.

every `app` stanza has a required `build` and `deploy` level-1 sub-stanzas and an optional level-1 `release` sub-stanza.

`hook` level-2 substanza can be used to run a command before or after any operation in `build`, `registry`, `deploy`, and `release` sub-stanzas.

```
app -> build -> hook
app -> build -> registry -> hook
app -> deploy -> hook
app -> release -> hook
```
