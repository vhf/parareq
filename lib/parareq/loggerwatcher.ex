defmodule ParaReq.LoggerWatcher do
  require Logger
  def start_link(manager) do
    Logger.info("Starting link #{__MODULE__}")
    GenServer.start_link(__MODULE__, manager, [])
  end

  def init(event_manager) do
    Logger.info("Initializing #{__MODULE__}")
    :ok = GenEvent.add_mon_handler(event_manager, ParaReq.Logger, self)
    {:ok, event_manager}
  end
end
