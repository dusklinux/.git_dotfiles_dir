
# 🚀 A Practical Guide to Neovim

Welcome to your new superpower. This guide breaks down Neovim's essential commands into a logical, step-by-step learning path. We'll focus on the most common and powerful keybinds you'll use every day.

> [!NOTE] The Vim Philosophy: Modal Editing
> Neovim, like its predecessor Vim, is a **modal editor**. This means the keys on your keyboard change their function depending on the mode you are in. The three essential modes are:
> - **`NORMAL` Mode:** The default mode for navigation, deletion, copying, and other commands. You'll spend most of your time here. (Press `<Esc>` to return to Normal mode from any other mode).
> - **`INSERT` Mode:** The mode for typing text like in a traditional editor.
> - **`VISUAL` Mode:** The mode for selecting text to operate on.

---

## Level 1: Survival Skills 🛡️

These are the absolute essentials for opening a file, making a small change, and getting out without breaking anything.

### ➤ Entering Insert Mode

To start typing, you must leave `NORMAL` mode and enter `INSERT` mode.

| Key | Action |
|:---|:---|
| `i` | **I**nsert text *before* the cursor. |
| `a` | **A**ppend text *after* the cursor. |
| `I` | Insert text at the **beginning** of the current line. |
| `A` | Append text at the **end** of the current line. |
| `o` | **O**pen a new line *below* the current line and enter Insert mode. |
| `O` | **O**pen a new line *above* the current line and enter Insert mode. |

### ➤ Basic Navigation

In `NORMAL` mode, use the home row keys to move. It's awkward at first but becomes incredibly efficient.

| Key | Direction |
|:---|:---|
| `h` | Move Left |
| `j` | Move Down |
| `k` | Move Up |
| `l` | Move Right |

### ➤ Saving and Quitting

Commands that start with a colon (`:`) are entered in **Command-line mode**.

| Command | Description |
|:---|:---|
| `:w` | **W**rite the file (Save). |
| `:q` | **Q**uit the current file. Fails if there are unsaved changes. |
| `:q!` | Quit **without** saving. The `!` forces the action. |
| `:wq` | **W**rite and **Q**uit (Save and Exit). |
| `:x` | A more efficient `:wq`. It only writes if there are changes. |

---

## Level 2: The Editor's Toolkit 🛠️

Now that you can survive, let's learn the core editing commands. All of these are used in `NORMAL` mode.

> [!TIP] The Dot Command: Your Best Friend
> The `.` key is one of the most powerful commands in Neovim. It **repeats the last change** you made. Did you just delete a word with `dw`? Move your cursor elsewhere and press `.` to delete another word. This is fundamental to the Vim workflow.

### ➤ Deleting Text

| Command | Action |
|:---|:---|
| `x` | Delete the character under the cursor. |
| `dd` | **D**elete the entire current line. |
| `D` | Delete from the cursor to the end of the line. |

### ➤ Yank (Copy) & Put (Paste)

Neovim's "copy" is called **yank**.

| Command | Action |
|:---|:---|
| `yy` | **Y**ank (copy) the entire current line. |
| `p` | **P**ut (paste) the yanked/deleted text *after* the cursor. |
| `P` | Put the yanked/deleted text *before* the cursor. |

### ➤ Change & Replace

The **change** operator (`c`) deletes text and immediately places you in Insert mode.

| Command | Action |
|:---|:---|
| `cc` | **C**hange (delete and enter Insert mode) the entire line. |
| `C` | Change from the cursor to the end of the line. |
| `r` | **R**eplace a single character under the cursor. |
| `R` | Enter **R**eplace mode to overwrite multiple characters. |

### ➤ Undo & Redo

| Command | Action |
|:---|:---|
| `u` | **U**ndo the last change. |
| `U` | Undo all recent changes on the current line. |
| `Ctrl` + `r` | **R**edo the last undone change. |

---

## Level 3: The Art of Motion 🏃

The true power of Neovim comes from combining **operators** (`d`elete, `y`ank, `c`hange) with **motions**.

> [!IMPORTANT] The Vim Grammar: `Operator + [Number] + Motion`
> Think of it like a language. You form "sentences" to edit text.
> - `d` (operator) + `w` (motion) = `dw` (delete word)
> - `c` (operator) + `$` (motion) = `c$` (change to end of line)
> - `y` (operator) + `2` (number) + `j` (motion) = `y2j` (yank this line and 2 below)

### ➤ Common Motions

| Motion | Moves the cursor... | Example |
|:---|:---|:---|
| `w` | to the start of the next **w**ord. | `dw` (delete word) |
| `b` | **b**ack to the start of the previous word. | `db` (delete back a word) |
| `e` | to the **e**nd of the current word. | `de` (delete to end of word) |
| `0` | to the absolute start of the line (column 0). | `d0` (delete to start of line) |
| `^` | to the first non-whitespace character of the line. | `c^` (change to first char) |
| `$` | to the end of the line. | `y$` (yank to end of line) |
| `gg` | to the **first line** of the file. | `dgg` (delete to start of file) |
| `G` | to the **last line** of the file. | `yG` (yank to end of file) |
| `[num]G` | to a specific line number (e.g., `10G`). | `10G` (go to line 10) |
| `%` | to the matching bracket (`()`, `{}`, `[]`). | `d%` (delete inside brackets) |

---

## Level 4: Visual Selection 🎨

`VISUAL` mode allows you to select text and then run a command on the selection.

### ➤ Entering Visual Mode

| Command | Action |
|:---|:---|
| `v` | Enter character-wise **V**isual mode. |
| `V` | Enter line-wise **V**isual mode (selects whole lines). |
| `Ctrl`+`v` | Enter **V**isual Block mode (selects rectangular blocks of text). |

Once in Visual mode, use motion keys (`h,j,k,l,w,b,$`, etc.) to expand your selection. Then, press an operator key (`d`, `y`, `c`) to act on the highlighted text.

> [!TIP] Saving a Selection to a File
> 1. Select text using any Visual mode (`v`, `V`, `Ctrl-v`).
> 2. Press `:`. The command line will automatically be filled with `:'<,'>`.
> 3. Type `w new_filename.txt` and press Enter.
>
> ```vim
> :'<,'>w new_filename.txt
> ```
> This saves only the selected text to a new file.

---

## Level 5: Search, Replace, Conquer 🔍

Efficiently find and modify text across your entire file.

### ➤ Finding Text

| Command | Action |
|:---|:---|
| `/pattern` | Search **forward** for `pattern`. |
| `?pattern` | Search **backward** for `pattern`. |
| `n` | Go to the **n**ext match in the same direction. |
| `N` | Go to the **p**revious match (opposite direction). |
| `:nohl` | Clears the search highlighting. |


### ➤ Search Settings

These are set using the `:set` command.

| Command | Description |
|:---|:---|
| `:set ic` | **I**gnore **C**ase for searches. |
| `:set noic` | Turn off ignore case. |
| `:set hls` | **H**igh**l**ight **S**earch results. |
| `:set nohlsearch` | Turn off highlight search. |
| `:set incsearch` | Show search matches **inc**rementally as you type. |

### ➤ The Substitute Command

The `:substitute` command (`:s`) is a powerhouse for find-and-replace.

| Command           | Action                                                                        |
| :---------------- | :---------------------------------------------------------------------------- |
| `:s/old/new/g`    | On the **current line**, substitute all (`/g`) instances of `old` with `new`. |
| `:%s/old/new/g`   | On **every line** in the file (`%`), substitute all instances.                |
| `:%s/old/new/gc`  | Same as above, but **c**onfirm (`/c`) each replacement.                       |
| `:#,#s/old/new/g` | On a specific range of lines (e.g., `:10,20s/...`), substitute all.           |
| `:%s/^/add before` | Add something to all line at the beginning |
| `:%s/$/add after` | Add something to all line at the end |
#### To add somethign at the beggining of selected line/all lines. 


---

## Level 6: Power User Techniques ✨

Commands to streamline your workflow.

### ➤ Jumping

| Command | Action |
|:---|:---|
| `Ctrl` + `o` | Jump to your **o**lder cursor position in the jump list. |
| `Ctrl` + `i` | Jump forward (the opposite of `Ctrl-o`). |
| `Ctrl` + `g` | Show file status, path, and cursor location (line number, percentage). |

### ➤ Executing External Commands

Run any shell command directly from Neovim.

```bash
# List files in the current directory
:!ls -l

# Read the contents of another file into the current buffer
:r /path/to/other/file.txt
```

### ➤ Macros: Automating Repetition

Macros record a sequence of keystrokes and let you play them back. This is perfect for complex, repetitive tasks.

1.  **Start Recording:** Press `q` followed by a letter to store the macro (e.g., `qa`). You'll see "recording @a" at the bottom.
2.  **Perform Actions:** Execute any sequence of Normal mode commands.
3.  **Stop Recording:** Press `q` again.
4.  **Playback:** Press `@` followed by the register letter (e.g., `@a`).
5.  **Repeat Last Macro:** Press `@@` to run the last-used macro again.
6. You can also repeat the last used macro with period "**.**"

> [!TIP] Applying a Macro to Multiple Lines
> The most efficient way to run a macro on many lines is with a Visual selection.
> 1. Record your macro (e.g., `qa...q`).
> 2. Go to the first line you want to change.
> 3. Press `V` to enter Visual Line mode.
> 4. Use `j` to select all the lines you want to affect.
> 5. Type `:normal @a` and press Enter.
>
> This executes the macro `@a` in `normal` mode for every selected line.

