defmodule UiGraph.Schema.PubSub do
  use Absinthe.Schema.Notation

  object :pubsub_subscription do
    field :sub_id, non_null(:integer)
    field :topic, non_null(:integer)
    field :subtopic, non_null(:integer)
  end

  object :pubsub do
    field :count, non_null(:integer)
    field :free, non_null(:integer)
    field :max, non_null(:integer)
    field :list, type: list_of(:pubsub_subscription)
  end

  [%Vex.Message.Data.Pubsub.List{flag: %Vex.Frame.DATA.FLAG{end: false,
    error: false, pub: false}, req_id: 4, ticks: 248438,
   value: [%Vex.Message.Data.Pubsub.Item{flag: %Vex.Frame.DATA.FLAG{end: false,
      error: false, pub: false}, index: 0, req_id: 4, sub_id: 3,
     sub_subtopic: 255, sub_topic: 2, ticks: 248438}]},
  %Vex.Message.Data.Pubsub.Count{flag: %Vex.Frame.DATA.FLAG{end: false,
    error: false, pub: false}, req_id: 4, ticks: 248438, value: 1},
  %Vex.Message.Data.Pubsub.Free{flag: %Vex.Frame.DATA.FLAG{end: false,
    error: false, pub: false}, req_id: 4, ticks: 248438, value: 9},
  %Vex.Message.Data.Pubsub.Max{flag: %Vex.Frame.DATA.FLAG{end: false,
    error: false, pub: false}, req_id: 4, ticks: 248438, value: 10},
  %Vex.Message.Data.Pubsub.All{flag: %Vex.Frame.DATA.FLAG{end: true,
    error: false, pub: false}, req_id: 4, ticks: 248438}]

  object :pubsub_queries do
    field :pubsub, type: :pubsub do
      resolve fn (_, _, _) ->
        pubsub =
          try do
            {:ok, [
              %Vex.Message.Data.Pubsub.List{ value: list },
              %Vex.Message.Data.Pubsub.Count{ value: count },
              %Vex.Message.Data.Pubsub.Free{ value: free },
              %Vex.Message.Data.Pubsub.Max{ value: max },
              %Vex.Message.Data.Pubsub.All{}
            ]} = Vex.RPC.read(:pubsub, :all)
            %{
              count: count,
              free: free,
              max: max,
              list: for %Vex.Message.Data.Pubsub.Item{ sub_id: sub_id, sub_topic: topic, sub_subtopic: subtopic } <- list, into: [] do
                %{
                  sub_id: sub_id,
                  topic: topic,
                  subtopic: subtopic
                }
              end
            }
          catch _, _ ->
            nil
          end
        {:ok, pubsub}
      end
    end
  end

end
