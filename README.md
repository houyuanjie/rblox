# Rblox

_Lox_ is a programming language introduced in [_Crafting Interpreters_](https://www.craftinginterpreters.com/)

The author's original implementation is at [munificent/craftinginterpreters](https://github.com/munificent/craftinginterpreters)

## Build and Install

```sh
$ rake install
```

## Usage

```sh
$ rblox [script]
```

## Debug

This project is configured for debugging in VS Code

### Prerequisites

Install one of the following VS Code extensions:

- [Ruby LSP](https://marketplace.visualstudio.com/items?itemName=Shopify.ruby-lsp)
- [VSCode Ruby rdbg Debugger](https://marketplace.visualstudio.com/items?itemName=KoichiSasada.vscode-rdbg)

### Debugging Steps

1. Open the project folder in VS Code.
2. In any Ruby source file, add a breakpoint by clicking in the gutter to the left of the line number.
3. Go to the `Run and Debug` view.
4. From the dropdown menu, select the configuration that matches your installed extension ([ruby-lsp] or [rdbg]):
   > Choose `... (prompt)` to debug the interactive REPL.
   > Choose `... (debug/main.lox)` to debug the debug/main.lox script (Created by yourself).
5. Press green play icon to start debugging.
6. Enjoy exploring.
