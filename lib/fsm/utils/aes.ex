defmodule Fsm.AES do
    @block_size 16
    @secret_key ".jG<T9qX6sNk3.Z3"

    def encrypt(text) do
        secret_key_hash = hash(@secret_key, 32)
        # create random Initialisation Vector
        iv = :crypto.strong_rand_bytes(16)

        text = pad(text, @block_size)
        encrypted_text = :crypto.crypto_one_time(:aes_256_cbc, secret_key_hash, iv, text, true )
        encrypted_text = ( iv <>  encrypted_text )
        
        Base.encode64(encrypted_text)
    end

    def decrypt(ciphertext) do
        secret_key_hash = hash(@secret_key, 32)

        {:ok, ciphertext} = Base.decode64(ciphertext)
        <<iv::binary-16, ciphertext::binary>> = ciphertext
        decrypted_text = :crypto.crypto_one_time(:aes_256_cbc, secret_key_hash, iv, ciphertext, false)

        unpad(decrypted_text)
    end
    
    def unpad(data) do
        to_remove = :binary.last(data)
        :binary.part(data, 0, byte_size(data) - to_remove)
    end
    
    # PKCS5Padding
    def pad(data, block_size) do
        to_add = block_size - rem(byte_size(data), block_size)
        data <> :binary.copy(<<to_add>>, to_add)
    end

    def hash(text, length) do
		:crypto.hash(:sha256, text)
		|> Base.url_encode64
		|> binary_part(0, length)
	end

end