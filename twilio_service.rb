require "twilio-ruby"

class TwilioService

  def send(message)
    begin
      account_sid = ENV["TWILIO_ACCOUNT_SID"]
      auth_token = ENV["TWILIO_AUTH_TOKEN"]
      client = Twilio::REST::Client.new(account_sid, auth_token)

      from = ENV["TWILIO_FROM"] # Your Twilio number
      to = ENV["TWILIO_TO"] # Your mobile phone number

      client.messages.create(
        from: from,
        to: to,
        body: message
      )
    rescue Twilio::REST::RestError
      return
    end
  end

end