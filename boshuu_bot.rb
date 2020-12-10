require 'discordrb'
require 'httpclient'
require 'json'
require 'date'
require 'time'
require 'pg'

bot = Discordrb::Commands::CommandBot.new(
  token: ENV['TOKEN'],
  client_id: ENV['CLIENT_ID'],
  prefix: '/'
)
assign_time_hour = 16
assign_time_min = 0o0
exec_count = 0
application_id = ENV['APPLICATION_ID']
# channel_id_boshuu = '764701181783572500'
channel_id_boshuu = "549143999814959124"#テスト

# uri = URI.parse(ENV['DATABASE_URL'])
uri = URI.parse('postgres://diicnrflmhopgx:dd5ea1e5d5846f0af031900f5b74aecac79d00627a6c5d2b2f4157e4ec8132ae@ec2-54-205-248-255.compute-1.amazonaws.com:5432/ddo0jjq166l8cv')
conn = PG.connect(
  host: uri.hostname,
  dbname: uri.path[1..-1],
  user: uri.user,
  port: uri.port,
  password: uri.password
)

bot.ready do |_event|
  bot.game = "募集をかけるチャンネルで/setupを送信してください"
end

bot.command :setup do |event|

  user_id = event.user.id
  server_id = event.server.id
  channel_id = event.channel.id
  boshuu_line = ""
  boshuu_time = ""

  bot.send_message(channel_id, "募集時の文言を設定してください")
  bot.message(from:user_id,in:channel_id) do |boshuu_event|
    if boshuu_line == ""
      boshuu_line = boshuu_event.message.content
    elsif boshuu_time == ""
      boshuu_time = boshuu_event.message.content
    end
  end
  while boshuu_line == "" do
    sleep 0.5
  end
  bot.send_message(channel_id, "募集時刻を指定してください\n例：16:00")
  while boshuu_time == "" do
    sleep 0.5
  end

  boshuu_time_hour = Time.parse(boshuu_time).hour
  boshuu_time_min = Time.parse(boshuu_time).min

  rows = conn.exec("
    select *
    from server_info
    where server_id = #{server_id}
    ")
  row=rows.first
  if row == nil
    conn.exec("
      insert into server_info(
        server_id,
        channel_id,
        boshuu_line,
        boshuu_time_hour,
        boshuu_time_min
      )
      values(
        '#{server_id}',
        '#{channel_id}',
        '#{boshuu_line}',
        '#{boshuu_time_hour}',
        '#{boshuu_time_min}'
      )
    ")
    bot.send_message(channel_id, "設定が完了しました。設定を変更する場合は再度/setupを送信してください")
  else
    conn.exec("
      update server_info
      set
        channel_id = '#{channel_id}',
        boshuu_line = '#{boshuu_line}',
        boshuu_time_hour = '#{boshuu_time_hour}',
        boshuu_time_min = '#{boshuu_time_min}'
      where server_id = #{server_id}
      ")
      bot.send_message(channel_id, "変更が完了しました。設定を変更する場合は再度/setupを送信してください")
  end

end

bot.heartbeat do |_event|

  now_hour = Time.now.hour
  now_min = Time.now.min

  rows = conn.exec("
    select *
    from server_info
    ")

  rows.each do |server_info|

    server_id = server_info['server_id']
    channel_id = server_info['channel_i']
    boshuu_time_hour = server_info['boshuu_time_hour']
    boshuu_time_min = server_info['boshuu_time_min']
    boshuu_line = server_info['boshuu_line']

    if boshuu_time_hour == now_hour && boshuu_time_min <= now_min && exec_count == 0

      url = "https://api.wotblitz.asia/wotb/tournaments/list/?application_id=#{application_id}&fields=start_at%2Ctitle%2Ctournament_id"
      client = HTTPClient.new
      response = client.get(url)
      results = JSON.parse(response.body)
      qt_count = 0

      results['data'].each do |result|

        today_unix = Date.today.to_time.to_i
        starboshuut_at_date_unix = Time.at(result['start_at']).to_date.to_time.to_i
        tournament_id = result['tournament_id']

        next unless today_unix == start_at_date_unix

        url = "https://api.wotblitz.asia/wotb/tournaments/stages/?application_id=#{application_id}&tournament_id=#{tournament_id}"
        client = HTTPClient.new
        response = client.get(url)
        result = JSON.parse(response.body)

        if server_id == 282106241973747712
          if result['meta']['total']
            title = result['data']['title']
            bot.send_message(channel_id, %(/poll "#{title}" "19:00" "19:30" "19:55" "未定" "参加不可"))
          elsif qt_count == 0
            bot.send_message(channel_id, %(/poll "クイック出場可能時間" "20:00" "20:30" "21:00" "Tier8希望" "Tier10希望" "未定" "参加不可"))
            bot.send_message(channel_id, 'mention8')
            bot.send_message(channel_id, "#{Date.today.month}月#{Date.today.day}日　Tier8・10クイックトーナメント募集。Simple Pollの投稿の出れる時間と希望Tierのリアクションを押してください")
          end
        else
          bot.send_message(channel_id, "#{boshuu_line}")
        end
          qt_count = 1
      end
      exec_count = 1
    end

    if assign_time_hour < now_hour && exec_count == 1
      exec_count = 0
    end
  end


end

bot.run
