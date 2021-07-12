defmodule Fsm.Helpers do
    @moduledoc """
    Helper functions
    """
    require Logger
    @doc """
    Generate a url safe random string
    """
    def url_safe_rand_string(length) when is_integer(length) do
        :crypto.strong_rand_bytes(length)  
        |> Base.url_encode64 
        |> binary_part(0, length)
    end

    def make_attachment_filename(inspection_id, file_ext) do
        "attachment_" <> to_string(inspection_id) <> "_" <> url_safe_rand_string(6) <> "." <> file_ext
    end

    def get_s3_object_url(filename) do
        bucket = Application.get_env(:ex_aws, :s3)[:bucket_name]
        "https://" <> bucket <> ".s3.amazonaws.com/" <> filename
    end

    def get_filename_from_url(url) do
        items = URI.parse(url) 
        |> Map.get(:path) 
        |> String.split("/")
        Logger.info fn -> "items: #{inspect items}" end
        case items do
            [_,bucket, filename] ->
                {:ok,bucket, filename}
            _ ->
                {:error, "invalid url"}
        end
    end

    def remove_url_query(url) do
        [hd | _] = String.split(url, "?")
        {:ok, hd}
    end

    def get_subscription_type_from_product_name(product) do
        case String.contains?(product, "month") do
            true->
               "monthly"
            false->
                case String.contains?(product, "year") do
                    true ->
                        "yearly"
                    false->
                       nil
                end
        end
    end

    def email_regex do
        ~r/^[a-z0-9](\.?[\w.!#$%&’*+\-\/=?\^`{|}~]){0,}@[a-z0-9-]+\.([a-z]{1,6}\.)?[a-z]{2,6}$/i
      #    ~r/^[\w.!#$%&’*+\-\/=?\^`{|}~]+@([a-zA-Z0-9-]+)\.([a-zA-Z0-9-]+)*$/i
    end
    @hex_values ["a", "b", "c", "d", "e", "f", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]
    def hex(length) do
        Enum.reduce(0..(length - 1), "", fn _, acc -> acc <> Enum.random(@hex_values) end)
    end

    def normalize(term) do
        term
        |> String.upcase()
        |> String.trim()
        |> String.split()
        |> Enum.map(fn x -> x |> String.replace(~r/\W/u, "") end)
        |> Enum.join(" & ")
    end

end
