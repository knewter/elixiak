defmodule Elixiak.Model do

	defmacro __using__(_opts) do
		quote do
			import Elixiak.Model.Document
			alias Elixiak.Util

			def bucket() do
				__MODULE__.__model__(:name)
			end

			def serialize(doc) do
				{:ok, json} = JSON.encode(__MODULE__.Obj.__obj__(:obj_kw, doc))

				key = case doc.key do
					nil -> :undefined
					value -> value
				end

				{bucket(), key, json, doc.metadata}
			end

			def unserialize(nil) do nil end
			def unserialize({json, key, metadata}) do
				{:ok, decoded} = JSON.decode(json)
				__MODULE__.new([{:metadata, metadata} | [{:key, key} | Util.list_to_args(HashDict.to_list(decoded), [])]])
			end

			def unserialize(json) do
				{:ok, decoded} = JSON.decode(json)
				__MODULE__.new(Util.list_to_args(HashDict.to_list(decoded), []))
			end
		end
	end
end

defmodule Elixiak.Model.Document do

  defmacro document(name, { :__aliases__, _, _ } = obj) do
    quote bind_quoted: [name: name, obj: obj] do
      def new(), do: unquote(obj).new()
      def new(params), do: unquote(obj).new(params)
      def __model__(:name), do: unquote(name)
      def __model__(:obj), do: unquote(obj)
    end
  end

  defmacro document(name, opts // [], [do: block]) do
    quote do
      name = unquote(name)
      opts = unquote(opts)

      defmodule Obj do
        use Elixiak.Obj, Keyword.put(opts, :model, unquote(__CALLER__.module))
        unquote(block)
      end

      document(name, Obj)
    end
  end
end