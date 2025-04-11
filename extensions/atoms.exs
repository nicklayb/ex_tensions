defmodule Nb.Atoms do
  @moduledoc """
  Usage example

  ```elixir
  Nb.Atoms.modules(&Nb.Atoms.ecto_schema?/1) # lists every ecto schema
  Nb.Atoms.modules(&Nb.Atoms.namespaced(&1, "Caltar") and Nb.Atoms.ecto_schema?(&1)) # lists every ecto schema in Vegas namespace
  ```

  """

  def atoms do
    for i <- 0..(atom_count() - 1), do: :erlang.binary_to_term(<<131, 75, i::24>>)
  end

  def atom_count, do: :erlang.system_info(:atom_count)

  def modules(predicate \\ fn _ -> true end) do
    Enum.filter(atoms(), &(module?(&1) and predicate.(&1)))
  end

  def module?(module), do: String.contains?(inspect(module), ".") and Code.ensure_loaded?(module)

  def live?(module, kind \\ nil) do
    case {kind, has_function?(module, {:__live__, 0})} do
      {nil, nil} -> false
      {_, nil} -> false
      {nil, _} -> true
      {_, _} -> Map.get(module.__live__(), :kind) == :view
    end
  end

  def struct?(module) do
    has_function?(module, {:__struct__, 0})
  end

  def ecto_schema?(module) do
    has_function?(module, {:__schema__, 1}) and has_function?(module, {:__schema__, 2})
  end

  def ecto_schema?(module, options) do
    ecto_schema?(module) and ecto_options?(module, options)
  end

  @options ~w(persisted?)a
  defp ecto_options?(module, [{option_key, _} = option | tail]) when option_key in @options do
    ecto_options?(module, option) and ecto_options?(module, tail)
  end

  defp ecto_options?(module, {:persisted?, false}), do: module.__schema__(:primary_key) == []

  defp ecto_options?(module, {:persisted?, true}),
    do: not ecto_options?(module, {:persisted?, false})

  defp ecto_options?(_, _), do: true

  def namespaced?(module, namespace) do
    String.starts_with?(inspect(module), namespace)
  end

  defp has_function?(module, definition) do
    not is_nil(Enum.find(module.__info__(:functions), fn def -> def == definition end))
  end
end
