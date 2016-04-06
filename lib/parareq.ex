defmodule ParaReq.App do
  use Application

  def start(type, args) do
    ret = ParaReq.start type, args
    ParaReq.Pool.start
    ret
  end

  def main(args) do
    start :normal, args
  end
end
