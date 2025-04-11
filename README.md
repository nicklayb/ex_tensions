# Elixir Extensions

Some modules that gets loaded in every project as a custom developer toolkit.

Everything is gitignored except what's in the repo so it's easier to add other extensions without commiting.

## Usage in a Nix flake

The flake needs to make use of Home Manager and have the following

```nix
home.file.".iex.exs".source = "${inputs.elixir-extensions}/iex.exs";
home.file.".elixir".source = "${inputs.elixir-extensions}/extensions";
```

By having `.iex.exs` in my home, this file is read everytime I start a Iex shell so my custom modules will be evaluated.

## Global extensions

By default, all files in `.elixir` gets loaded. Those in the repo as well as the custom ones that gets added.

## Project extensions

All me developer work is in `~/dev`, so if I checkout a repo from my personal account, it'll be in `nicklayb/my_repo`. If I add a custom `.elixir/nicklayb/my_repo.exs`, this file will get loaded along with the project.


