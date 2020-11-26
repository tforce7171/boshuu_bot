#discordapp.com/oauth2/authorize?client_id=770654456231493633&scope=bot&permissions=0

require 'discordrb'
require 'httpclient'
require 'json'
require 'date'
require 'time'

bot = Discordrb::Commands::CommandBot.new(
token: ENV['TOKEN'],
client_id: ENV['CLIENT_ID'],
prefix:'/',
)
assign_time_hour = 16
assign_time_min = 00
exec_count = 0
application_id = ENV['APPLICATION_ID']
clan_ids = ["1845","6800","29274","34796","16297"]
access_token = ENV['ACCESS_TOKEN']
# channel_id_boshuu = "764701181783572500"
# channel_id_thirty = "451034405721473026"
channel_id_boshuu = "549143999814959124"
channel_id_thirty = "549143999814959124"

bot.heartbeat do |event|

  # bot.send_message(764701181783572500, "tick")
  #bot.send_message(channel_id_boshuu, "exec_count-#{exec_count}")

  now_hour = Time.now.hour
  now_min = Time.now.min

  if assign_time_hour == now_hour && assign_time_min <= now_min && exec_count == 0
    # bot.send_message(764701181783572500,"starting")

    url = "https://api.worldoftanks.asia/wot/auth/prolongate/?application_id=#{application_id}&access_token=#{access_token}"
    client = HTTPClient.new
    response = client.get(url)
    result = JSON.parse(response.body)

    # if result["data"]["access_token"]
    #   access_token = result["data"]["access_token"]
    #   ENV['ACCESS_TOKEN'] = access_token
    # else
      bot.send_message(channel_id_boshuu,"#{result}")
    #end

    url = "https://api.wotblitz.asia/wotb/tournaments/list/?application_id=#{application_id}&fields=start_at%2Ctitle%2Ctournament_id"
    client = HTTPClient.new
    response = client.get(url)
    results = JSON.parse(response.body)
    qt_count = 0

    # bot.send_message(764701181783572500,"api parsed")
    # if results["data"]
    #   bot.send_message(764701181783572500,"api retrieved")
    # end

    results["data"].each do |result|
      today_unix = Date.today.to_time.to_i
      start_at_date_unix = Time.at(result["start_at"]).to_date.to_time.to_i
      tournament_id = result["tournament_id"]

      # bot.send_message(764701181783572500,"#{today_unix};#{start_at_date_unix};#{tournament_id}")

      if today_unix == start_at_date_unix

        # bot.send_message(764701181783572500,"date match found")

        url = "https://api.wotblitz.asia/wotb/tournaments/stages/?application_id=#{application_id}&tournament_id=#{tournament_id}"
        client = HTTPClient.new
        response = client.get(url)
        result = JSON.parse(response.body)

        if result["meta"]["total"]
          title = result["data"]["title"]
          bot.send_message(channel_id_boshuu, %Q[/poll "#{title}" "19:00" "19:30" "19:55" "未定" "参加不可"])
        elsif qt_count == 0
          bot.send_message(channel_id_boshuu, %Q[/poll "クイック出場可能時間" "20:00" "20:30" "21:00" "Tier8希望" "Tier10希望" "未定" "参加不可"])
          bot.send_message(channel_id_boshuu, "mention8")
          bot.send_message(channel_id_boshuu, "#{Date.today.month}月#{Date.today.day}日　Tier8・10クイックトーナメント募集。Simple Pollの投稿の出れる時間と希望Tierのリアクションを押してください")
          qt_count = 1
        end
      end
    end

    exec_count = 1
    #bot.send_message(channel_id_boshuu, "exec_count-#{exec_count}")
    # bot.send_message(764701181783572500,"over")
  end

  if assign_time_hour < now_hour && exec_count == 1
    exec_count = 0
    #bot.send_message(channel_id_boshuu, "exec_count-#{exec_count}")
    # bot.send_message(764701181783572500,"exec_count reset")
  end
end

bot.command :buku do |event|

  bot_message = event.message.content
  bot_message.slice!(0,5)
  date_range = bot_message.to_i

  today = Date.today

  clan_ids.each do |clan_id|

    url = "https://api.wotblitz.asia/wotb/clans/info/?application_id=#{application_id}&clan_id=#{clan_id}&fields=tag%2Cmembers_ids"
    client = HTTPClient.new
    response = client.get(url)
    result = JSON.parse(response.body)

    tag = result["data"]["#{clan_id}"]["tag"]
    bot.send_message(channel_id_thirty, "|#{tag}|")

    result["data"]["#{clan_id}"]["members_ids"].each do |member_id|

      url = "https://api.wotblitz.asia/wotb/account/info/?application_id=#{application_id}&access_token=#{access_token}&account_id=#{member_id}&fields=nickname%2Clast_battle_time"
      client = HTTPClient.new
      response = client.get(url)
      result = JSON.parse(response.body)

      nickname = result["data"]["#{member_id}"]["nickname"]
      last_battle_time_unix = result["data"]["#{member_id}"]["last_battle_time"]
      last_battle_date = Time.at(last_battle_time_unix).to_date
      date_since_last_battle = (today - last_battle_date).to_i

      if date_range <= date_since_last_battle
        bot.send_message(channel_id_thirty, "#{nickname} : #{date_since_last_battle}日")
      end

    end

  end
  bot.send_message(channel_id_thirty, "done")
end

bot.command :test do |event|

  url = "https://api.worldoftanks.asia/wot/auth/login/?application_id=#{application_id}&nofollow=1"
  client = HTTPClient.new
  response = client.get(url)
  result = JSON.parse(response.body)
  
  bot.send_message(channel_id_boshuu,"#{result}")

  # url = "https://api.worldoftanks.asia/wot/auth/prolongate/?application_id=#{application_id}&access_token=#{access_token}"
  # client = HTTPClient.new
  # response = client.get(url)
  # result = JSON.parse(response.body)
  #
  # bot.send_message(channel_id_boshuu,"#{result}")
  #
  # access_token = result["data"]["access_token"]
  # ENV['ACCESS_TOKEN'] = access_token

end

bot.run
