defmodule Flight.KnowledgeBase do
    alias Flight.KnowledgeBase.ZipCode
    alias Flight.Repo
    
    def get_zipcode(nil), do: nil
    def get_zipcode(zip_code) do
        Repo.get_by(ZipCode, zip_code: zip_code)
    end
end