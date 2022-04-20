defmodule FsmWeb.GraphQL.Squawks.SquawksResolvers do
    use FsmWeb.GraphQL.Errors
    alias Fsm.Squawks
    alias Fsm.Scheduling
    alias FsmWeb.GraphQL.EctoHelpers
    require Logger

    def get_squawk(_parent, %{id: squawk_id}, %{context: %{current_user: current_user}}) do
        squawk = Squawks.get_squawk(squawk_id)
        {:ok, squawk}
    end
    def get_squawk(_parent, _args, _context), do: @not_authenticated

    def get_squawks(_parent, args, %{context: %{current_user: %{id: user_id, roles: roles}}}=context) do
        squawks =
            cond do
                "mechanic" in roles ->
                    aircrafts = Map.get(args, :aircraft_id) || Scheduling.visible_air_assets(context)
                    Squawks.get_squawks(aircrafts)

                true ->
                    aircraft_id = Map.get(args, :aircraft_id)

                    Squawks.get_squawks({aircraft_id, user_id})

            end

        {:ok, %{squawks: squawks}}
    end
    def get_squawks(_parent, _args, _context), do: @not_authenticated

    def update_squawk(_parent, args, %{context: %{current_user: current_user}}) do
        case Squawks.get_squawk(args.id) do
            nil ->
                @not_found
            squawk ->
                Squawks.update_squawk(squawk, args.squawk_input)
        end

    end
    def update_squawk(_parent, _args, _context), do: @not_authenticated

    def delete_squawk(_parent, %{id: id}, %{context: %{current_user: current_user}}) do
        case Squawks.get_squawk_by_id_and_user_id(id, current_user.id) do
            nil ->
                @not_found
            squawk ->
                case Squawks.delete_squawk(squawk) do
                    {:ok, squawk} ->
                        {:ok, true}
                    {:error, reason} ->
                        {:error, false}
                end
        end

    end
    def delete_squawk(_parent, _args, _context), do: @not_authenticated

    def add_squawk(_parent,%{squawk_input: squawk_input, squawk_image_input: squawk_image_input}, %{context: %{current_user: current_user}}) do
        squawk_input = Map.put(squawk_input, :user_id, current_user.id)
        EctoHelpers.action_wrapped(fn ->
            Squawks.add_squawk_and_image(squawk_input, squawk_image_input)
        end)
    end

    def add_squawk(_parent,_args, %{context: %{current_user: current_user}}) do
        squawk_input = Map.put(_args.squawk_input, :user_id, current_user.id)
        EctoHelpers.action_wrapped(fn ->
            Squawks.add_squawk_only(squawk_input)
        end)
    end

    def add_squawk(_parent, _args, _context), do: @not_authenticated

    def add_squawk_image(_parent, %{squawk_image_input: squawk_image_input}, %{context: %{current_user: current_user}}) do

        EctoHelpers.action_wrapped(fn ->
            case Squawks.get_squawk(squawk_image_input.squawk_id) do
                nil ->
                    @not_found
                squawk ->
                  #Logger.info fn -> "squawk----: #{inspect squawk}" end
                    attrs = squawk_image_input
                            |> Map.put(:user_id, current_user.id)
                            |> Map.put(:squawk_id, squawk.id)
                            |> Map.put(:attachment_type, :squawk)

                    #Logger.info fn -> "attrs----: #{inspect attrs}" end
                    Squawks.add_squawk_image(attrs)
            end
        end)
    end
    def add_squawk_image(_parent, _args, _context), do: @not_authenticated

    def delete_squawk_image(_parent, %{id: id}, %{context: %{current_user: current_user}}) do
        EctoHelpers.action_wrapped(fn ->
            case Squawks.get_squawk_image(id, current_user.id) do
                nil ->
                    @not_found
                squawkImage ->
                    Squawks.delete_squawk_image(squawkImage)
            end
        end)
    end
    def delete_squawk_image(_parent, _args, _context), do: @not_authenticated

    def resolve_squawk(_parent, %{id: id}, %{context: %{current_user: current_user}}) do
        case Squawks.get_unresolved_squawk(id) do
            nil ->
                @not_found
            squawk ->
                attrs  =   %{
                            resolved: true
                            }

                Squawks.update_squawk(squawk, attrs)
        end

    end
    def resolve_squawk(_parent, _args, _context), do: @not_authenticated
end
