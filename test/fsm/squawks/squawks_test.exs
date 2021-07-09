defmodule Fsm.Squawks.SquawksTest do
    use Flight.DataCase
    use Bamboo.Test, shared: true
  
    import EctoEnum
    alias Fsm.Squawks
  
    describe "squawks" do
      @valid_attrs %{
        title: "First test sqwuak",
        serverity: :monitor,
        description: "Testing squawk in the morning",
        resolved: true,
        system_affected: :cockpit,
        user_id: 1
      }

      def squawk_fixture(attrs \\ %{}) do
        with create_attrs <- Map.merge(@valid_attrs, attrs),
             {:ok, squawk} <- Squawks.add_squawk(create_attrs)
        do
          squawk
        end
      end
  
      test "list_squawks/0 returns all squawks" do
        squawk = squawk_fixture()
        assert Squawks.get_squawks() == [squawk]
      end

      test "add_squawk/1 creates the squawk in the db and returns it" do
        before = Squawks.get_squawks()
        squawk = squawk_fixture()
        updated = Squawks.get_squawks()
        assert !(Enum.any?(before, fn u -> squawk == u end))
        assert Enum.any?(updated, fn u -> squawk ==u end)
      end

    end
end
    