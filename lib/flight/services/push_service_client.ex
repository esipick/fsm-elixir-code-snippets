defmodule Mondo.PushService.Client do
  def aws_publish(payload, endpoint_arn) do
    ExAws.SNS.publish(payload, target_arn: endpoint_arn, message_structure: :json)
    |> ExAws.request()
  end

  def aws_create_platform_endpoint(arn, token) do
    ExAws.SNS.create_platform_endpoint(arn, token)
    |> ExAws.request()
  end
end
