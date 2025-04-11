defmodule Nb.IO do
  @colors [number: :yellow, atom: :cyan, string: :green, boolean: :magenta, nil: :magenta]
  def inspect(message, options \\ []) do
    indentation =
      options
      |> Keyword.get(:indentation, 0)
      |> then(&List.duplicate(" ", &1 * 2))
      |> Enum.join()

    options =
      options
      |> Keyword.put(:syntax_colors, @colors)
      |> Keyword.update(:label, nil, &(indentation <> &1))

    IO.inspect(message, options)
  end
end

if Code.ensure_loaded?(Decorator.Define) do
  defmodule Nb.Decorators do
    @moduledoc """
    Usage example

        defmodule SomeModule to inspect
          use Nb.Decorators

          @decorate inspect_around()
          def some_function(...) do
            ...
          end
        end
    """
    use Decorator.Define,
      inspect_around: 0

    def inspect_around(body, context) do
      quote do
        indentation =
          :nboisvert_inspect
          |> Process.get(0)
          |> tap(&Process.put(:nboisvert_inspect, &1 + 1))

        Nb.IO.inspect(
          unquote(context.args),
          label: "#{unquote(context.name)}/#{unquote(context.arity)} <",
          indentation: indentation
        )

        tap(unquote(body), fn result ->
          Nb.IO.inspect(result,
            label: "#{unquote(context.name)}/#{unquote(context.arity)} >",
            indentation: indentation
          )

          Process.put(:nboisvert_inspect, 0)
        end)
      end
    end
  end
end
