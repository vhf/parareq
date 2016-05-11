defmodule ParaReq.LoggerWatcher do
  def start_link(manager) do
    GenServer.start_link(__MODULE__, manager, [])
  end

  def init do
    :ok = GenEvent.add_mon_handler(:manager, ParaReq.Logger, self())
    {:ok, :manager}
  end
end
