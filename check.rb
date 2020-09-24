require 'net/http'
require 'uri'
require 'json'
require 'twilio-ruby'

s = File.read("config.json")
@config = JSON.parse(s)
@client = Twilio::REST::Client.new @config['twilio']['account_sid'], @config['twilio']['auth_token']

def alert(message)
    @client.messages.create(
        from: @config['twilio']['number'],
        to: @config['settings']['primary'],
        body: message
    )
end

# init
down = false
last_alert = Time.new
while true
    resp = Net::HTTP.get URI('https://api.umd.io')
    parsed = JSON.parse resp

    if parsed["status"] != "error" then
        puts "Passed health check"
        if down then
            puts "Back online. Sending alerts."
            alert "umd.io is back up"
            down = false
        end
    else
        puts "Failed health check."
        down = true
        if Time.now - last_alert > (60 * 60 * 24)
            puts "Sending alert"
            alert "umd.io is down"
            last_alert = Time.now
        else
            puts "Sent an alert too recently. Sleeping."
        end
    end
    sleep(60 * 60)
end