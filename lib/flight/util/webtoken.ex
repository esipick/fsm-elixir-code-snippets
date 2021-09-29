defmodule Flight.Webtoken do
  @block_size 16
  @secret_key Application.get_env(:flight, :webtoken_secret_key)

  def encrypt(plain_text) do
    secret_key_hash = make_hash(@secret_key, 32)

    # create Initialisation Vector
    iv = :crypto.strong_rand_bytes(@block_size)

    padded_text = pad_pkcs7(plain_text, @block_size)
    encrypted_text = :crypto.crypto_one_time(:aes_256_cbc, secret_key_hash, iv, padded_text, true )

    # concatenate IV for decryption
    encrypted_text = ( iv <>  encrypted_text )

    Base.encode64(encrypted_text)
  end

  def decrypt(ciphertext) do
    secret_key_hash = make_hash(@secret_key, 32)

    {:ok, ciphertext} = Base.decode64(ciphertext)
    <<iv::binary-16, ciphertext::binary>> = ciphertext
    decrypted_text = :crypto.crypto_one_time(:aes_256_cbc, secret_key_hash, iv, ciphertext, false)

    unpad_pkcs7(decrypted_text)
  end

  defp pad_pkcs7(message, blocksize) do
    pad = blocksize - rem(byte_size(message), blocksize)
    message <> to_string(List.duplicate(pad, pad))
  end

  defp unpad_pkcs7(data) do
    <<pad>> = binary_part(data, byte_size(data), -1)
    binary_part(data, 0, byte_size(data) - pad)
  end

  defp make_hash(text, length) do
    :crypto.hash(:sha512, text)
    |> Base.encode16
    |> String.downcase
    |> String.slice(0, length)
  end

end
