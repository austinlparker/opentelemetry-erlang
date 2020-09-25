defmodule OpenTelemetry.ValueObserver do
  @moduledoc """

      require OpenTelemetry.ValueObserver

      OpenTelemetry.ValueObserver.set_callback("some.counter", fn o -> OpenTelemetry.ValueObserver.observe(o, 33, []))
  """

  defmacro new(name, opts \\ %{}) do
    quote do
      :otel_value_observer.new(:opentelemetry.get_meter(__MODULE__), unquote(name), unquote(opts))
    end
  end

  defmacro set_callback(observer, callback) do
    quote do
      :otel_meter.set_observer_callback(
        :opentelemetry.get_meter(__MODULE__),
        unquote(observer),
        unquote(callback)
      )
    end
  end

  defdelegate definition(name, opts), to: :otel_value_observer
  defdelegate observe(observer_result, number, label_set), to: :otel_value_observer
end
