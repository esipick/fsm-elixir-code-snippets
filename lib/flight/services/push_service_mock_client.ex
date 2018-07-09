defmodule Mondo.PushService.MockClient do
  def aws_publish(_payload, _target) do
    {:ok,
     %{
       body: %{
         message_id: "6fa0ed65-2d25-5c03-8119-be2bf625930a",
         request_id: "7e574cf9-4037-5505-a728-1fb79b376a0c"
       },
       headers: [
         {"x-amzn-RequestId", "7e574cf9-4037-5505-a728-1fb79b376a0c"},
         {"Content-Type", "text/xml"},
         {"Content-Length", "294"},
         {"Date", "Mon, 16 Apr 2018 17:09:20 GMT"}
       ],
       status_code: 200
     }}
  end

  def aws_create_platform_endpoint(_arn, _token) do
    {:ok, %{body: %{endpoint_arn: "arn:from:aws"}}}
  end
end
