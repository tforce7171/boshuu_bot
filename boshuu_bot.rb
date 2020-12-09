require 'discordrb'
require 'httpclient'
require 'json'
require 'date'
require 'time'

bot = Discordrb::Commands::CommandBot.new(
  token: ENV['TOKEN'],
  client_id: ENV['CLIENT_ID'],
  prefix: '/'
)
assign_time_hour = 16
assign_time_min = 0o0
exec_count = 0
application_id = ENV['APPLICATION_ID']
channel_id_boshuu = '764701181783572500'


bot.heartbeat do |_event|
  now_hour = Time.now.hour
  now_min = Time.now.min

  if assign_time_hour == now_hour && assign_time_min <= now_min && exec_count == 0

    url = "https://api.wotblitz.asia/wotb/tournaments/list/?application_id=#{application_id}&fields=start_at%2Ctitle%2Ctournament_id"
    client = HTTPClient.new
    response = client.get(url)
    results = JSON.parse(response.body)
    qt_count = 0

    results['data'].each do |result|
      today_unix = Date.today.to_time.to_i
      start_at_date_unix = Time.at(result['start_at']).to_date.to_time.to_i
      tournament_id = result['tournament_id']

      next unless today_unix == start_at_date_unix

      url = "https://api.wotblitz.asia/wotb/tournaments/stages/?application_id=#{application_id}&tournament_id=#{tournament_id}"
      client = HTTPClient.new
      response = client.get(url)
      result = JSON.parse(response.body)

      if result['meta']['total']
        title = result['data']['title']
        bot.send_message(channel_id_boshuu, %(/poll "#{title}" "19:00" "19:30" "19:55" "未定" "参加不可"))
      elsif qt_count == 0
        bot.send_message(channel_id_boshuu, %(/poll "クイック出場可能時間" "20:00" "20:30" "21:00" "Tier8希望" "Tier10希望" "未定" "参加不可"))
        bot.send_message(channel_id_boshuu, 'mention8')
        bot.send_message(channel_id_boshuu, "#{Date.today.month}月#{Date.today.day}日　Tier8・10クイックトーナメント募集。Simple Pollの投稿の出れる時間と希望Tierのリアクションを押してください")
        qt_count = 1
      end
    end

    exec_count = 1

  end
  if assign_time_hour < now_hour && exec_count == 1
    exec_count = 0
  end
end

bot.run
