require Logger

defmodule Nb.File do
  def current_folder, do: File.cwd!()
  def home, do: System.get_env("HOME")
  def dev_root, do: Path.join(home(), "/dev")
  def current_project, do: String.replace(current_folder(), dev_root(), "")
  def current_project_extension, do: "#{current_project()}.exs"
  def extensions, do: Path.join(home(), "/.elixir")
  def in_project?, do: current_project() != home()

  def elixir_script?(file), do: String.downcase(Path.extname(file)) == ".exs"
end

defmodule Nb do
  def load_extensions() do
    folder = Nb.File.extensions()

    folder
    |> File.ls!()
    |> Enum.filter(&Nb.File.elixir_script?/1)
    |> Enum.map(&load_file(folder, &1))
  end

  def load_project_extensions(file) do
    full_path = Path.join(Nb.File.dev_root(), file)

    if Nb.File.in_project?() do
      load_file(Nb.File.extensions(), file)
    else
      info(["Extensions", "Project"], "No project extension")
    end
  end

  defp load_file(folder, file) do
    full_path = Path.join(folder, file)

    if File.exists?(full_path) do
      Code.require_file(full_path)

      Nb.info(["Extensions"], "Loaded #{file}")
    else
      warning(["Extensions"], "No extension for #{file}")
    end
  rescue
    error ->
      error(["Extensions", file], inspect(error))
  end

  def info(keys \\ [], message) do
    Logger.info(green("#{wrap_keys(keys)} #{message}"))
  end

  def warning(keys \\ [], message) do
    Logger.warning(yellow("#{wrap_keys(keys)} #{message}"))
  end

  def error(keys \\ [], message) do
    Logger.error(red("#{wrap_keys(keys)} #{message}"))
  end

  defp wrap_keys(keys) do
    keys
    |> List.wrap()
    |> then(&["Nb" | &1])
    |> Enum.map_join(" ", &"[#{&1}]")
  end

  for color <- [:yellow, :reset, :cyan, :green, :red] do
    def unquote(color)(message) do
      apply(IO.ANSI, unquote(color), []) <> message <> IO.ANSI.reset()
    end
  end
end

try do
  Nb.load_extensions()

  Nb.load_project_extensions(Nb.File.current_project_extension())
rescue
  error ->
    Nb.error(inspect(error))
end
