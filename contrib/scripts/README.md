# scripts

## overview

this document is a refrence point to describe purpose of scripts in this folder

## spielbash-gen

### overview

Creating YAML instructions for `spielbash` can be tedious, mainly due to sensitivity of .yml files with spacing and indentation and also there are a lot of repetative lines which a simple mistake may lead to spielbash not being able to parse the file.

`spielbash-gen` is a bash script that reads a text file and generates corresponding `spielbash` instruction `script` YAML file.

### internals

essentially speaking, this script reads plain text files and generates
corresponding spielbash instruction YAML file. it generated YAML file has the following general :

- it launches `Vim` at start and runs all messages and commands through Vim and it`s Panes
- By default, every line is converted to a single, 'presistent' spielbash `Message` instruction, followed by `Enter` key press 
- if a line starts with `#` , it is converted to a 'volatile' spielbash `Message`, i.e a message that would be deleted after some period of time.
- what ever is inside a block starting with `### terminal` and ending with `### end ###` marker is converted to  spielbash `Commands` , run in a vim split Bash terminal pane. the script generates necessary lines to open a new pane and switch to it, run commands and at the end, close terminal pane and switch back to the main `Vim` instruction document.
is used mostly for demoing and showing how theory would look in practice. eg,:

```txt
### terminal ###
mkdir foo
touch foo/bar
### end ###
```

### considerations

this script is still in 'beta' and can have some flaws. always confirm the output before running, there are
some known bugs, for instance , in some cases, there are escaping issues with special characters in generated yml file

Keep in mind is that 'Message' string values are encapsulated in Double Quotes (") so make sure to use single quotes if needed in the input text files rather than double quotes

### post-processing

the following short sed snippets can be used to clean up
and run some post generation text editing

- clean up comments in the YAML file

```bash
sed -i  '/^#.*$/d' generated-spielbash-script.yml
```

- clean up empty `Messages` in the YAML file

```bash
sed -i.bak -e  '/  \- message: \"\"/,//{{/  \- message: \"\"/!{/\-/!{d;};};};};' generated-spielbash-script.yml
sed -i -e '/\- message: \"\"/d' generated-spielbash-script.yml
```

- clean up and remove trailing whitspace in strings encapsulated in Double Quotes (")

```bash
sed -i -e 's/\s*\"$/\"/g' generated-spielbash-script.yml
```

- clean up original input file and remove 'meta' lines, such as lines that start with '#'. keep in mind that this is a series of command:
  - command 1 : removes all lines starting with '#'
  - command 2 : removes text blocks starting with `### terminal ###` and ending in `### end ###`
  - command 3 : replaces multiple back to back empty lines with a single new line

```bash
# sed -i -e '/^@/d' raw-input
sed -i -e '{/### terminal ###/,/### end ###/{d}};' raw-input
sed -i -e '/^$/N;/^\n$/D' raw-input
```

- clean up raw md file

```bash
sed -i '/```/,/```/!d;:A;N;$bB;/\n$/!bA;:B;/### terminal ###/d' README.md
```