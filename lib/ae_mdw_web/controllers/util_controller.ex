defmodule AeMdwWeb.UtilController do
  use AeMdwWeb, :controller


  def status(conn, _params) do
    {:ok, top_kb} = :aec_chain.top_key_block()
    {_, _, node_vsn} = Application.started_applications() |> List.keyfind(:aecore, 0)

    status = %{
      node_version: to_string(node_vsn),
      node_height: :aec_blocks.height(top_kb),
      mdw_version: AeMdw.MixProject.project()[:version],
      mdw_height: AeMdw.Db.Util.last_gen()
    }

    json(conn, status)
  end

end
