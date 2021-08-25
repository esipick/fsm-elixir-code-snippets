defmodule Fsm.AppVersions do
  alias Fsm.AppVersions
  alias Fsm.AppVersion
  alias Flight.Repo

  import Ecto.Query, warn: false

  @doc """
  return lastest versions of the mobile apps
  """
  def get_app_version do
    version = Ecto.Query.from(v in AppVersion, order_by: [desc: v.created_at], limit: 1)
    |> Ecto.Query.first()
    |> Repo.one()

    version || get_default_version()
  end

  @doc """
  updates app version in database
  """
  def update_app_version(version) do
    case validate_version(version) do
      {:ok, int_version} ->
        version_attrs = %{
          version: version,
          int_version: int_version,
          android_version: version,
          android_int_version: int_version,
          ios_version: version,
          ios_int_version: int_version,
          web_version: version
        }
        %AppVersion{}
        |> AppVersion.changeset(version_attrs)
        |> Repo.insert()

      {:error, message} ->
        {:error, message}
    end
  end

  @doc """
  returns default fsm version
  """
  def get_default_version() do
    %{
      version: "4.1.1",
      int_version: 4_000_101,
      android_version: "4.1.1",
      android_int_version: 4_000_101,
      ios_version: "4.1.1",
      ios_int_version: 4_000_101,
      web_version: "4.1.1",
      created_at: "2021-08-25 12:00:00",
      updated_at: "2021-08-25 12:00:00"
    }
  end

  @doc """
  validates app version and returns int version
  """
  def validate_version(version) do
    parts =
      version
      |> String.split(".", trim: true)
      |> Enum.take(3)

    int_version(parts, Enum.count(parts))
  end

  defp int_version(parts, parts_count) when parts_count == 3 do
    Enum.reduce_while(parts, {:ok, ""}, fn part, {:ok, acc} ->
      part
      |> normalize_part(String.length(part))
      |> case do
        {:ok, part} -> {:cont, {:ok, acc <> part}}
        {:error, error} -> {:halt, {:error, error}}
      end
    end)
    |> case do
      {:ok, num} ->
        {int_version, _} = Integer.parse(num)
        {:ok, int_version}

      error ->
        error
    end
  end

  defp int_version(version, _),
    do:
      {:error,
       "invalid version: #{Enum.join(version, ".")}. version should be in xxx.yyy.zzz format, where x, y, z are numbers."}

  defp normalize_part(part, part_count) when part_count > 0 and part_count <= 3 do
    part
    |> String.pad_leading(3, "0")
    |> Integer.parse()
    |> case do
      {_, ""} ->
        {:ok, String.pad_leading(part, 3, "0")}

      _ ->
        {:error,
         "Version format is not valid. version should be in xxx.yyy.zzz format, where x, y, z are numbers."}
    end
  end

  defp normalize_part(_part, _part_count),
    do:
      {:error,
       "Version format is not valid. version should be in xxx.yyy.zzz format, where x, y, z are numbers."}
end
