require 'mysql2'
require 'curses'
require 'timeout'
require_relative './worker.rb'

datetime_regexp = /\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/

client = Mysql2::Client.new(
  host: 'localhost',
  username: 'root',
  password: 'Sql0463'
)
client.query("use stamp_app_on_terminal;")

Curses.init_screen 
Curses.curs_set(0) # invisible cursor

begin 
  win = Curses.stdscr

  # 名前の入力
  win.setpos(0, 0)
  win.addstr("名前を入力してください\n")
  win.addstr("名前: ")
  name = win.getstr

  # ユーザを検索
  users_results = client.query(
    <<~TEXT
    SELECT * 
    FROM users
    WHERE name = "#{name}"
    ;
    TEXT
  )
  if users_results.size.zero?
    win.addstr("ユーザが見つかりませんでした")
    win.getch
    Curses.close_screen
    exit
  end
  # p users_results.first 
  # win.getch

  user_id = users_results.first['id']
  worker = Worker.new(user_id, name)

  # 最新の勤務データを検索
  work_data_results = client.query(
    <<~TEXT 
    SELECT * 
    FROM work_data
    WHERE user_id = '#{user_id}'
    ORDER BY started_work_at DESC
    LIMIT 1
    ;
    TEXT
  )
  # p work_data_results.first
  # win.getch

  if work_data_results.size.positive? && work_data_results.first['finished_work_at'].nil?
    worker = Worker.new(user_id, name, work_data_results.first['started_work_at'])
  end
  
  log = ""

  loop do 
    win.clear
    win.setpos(0, 0)
    win.addstr(<<~TEXT
    ようこそ、#{name}さん

    勤務状況: #{worker.status}

    勤務時間: #{worker.working_hours}
    勤務開始時刻: #{worker.started_work_at}
    勤務終了時刻: #{worker.finished_work_at}

    コマンド: 
    出勤(s) 退勤(f) 休憩(b) 再開(r) 終了(q)

    [LOG] #{log}
    TEXT
    )
    win.refresh # refresh わからん...

    begin 
      Timeout.timeout(0.1) do
        command = win.getch
        case command
        when 's'
          if worker.status == '退勤済'
            log = "既に退勤しています"
            break 
          end
          if worker.status == '勤務中'
            log = "既に出勤しています"
            break 
          end
          worker = worker.start_work 
          log = "出勤しました"

          # データベースに出勤時間を記録
          client.query(
            <<~TEXT
            INSERT INTO work_data(started_work_at, user_id) 
            VALUES (
              '#{worker.started_work_at.to_s.scan(datetime_regexp).first}', 
              '#{worker.id}'
            )
            TEXT
          )

        when 'f'
          if worker.status == '出勤前'
            log = "まだ出勤していません"
            break 
          end
          if worker.status == '退勤済'
            log = "既に退勤しています"
            break 
          end
          worker = worker.finish_work 
          log = "退勤しました"

          # データベースに退勤時間を記録
          client.query(
            <<~TEXT
            UPDATE work_data
            SET finished_work_at = '#{worker.finished_work_at.to_s.scan(datetime_regexp).first}'
            WHERE started_work_at = '#{worker.started_work_at.to_s.scan(datetime_regexp).first}'
            AND user_id = #{worker.id}
            TEXT
          )

        when 'q'
          Curses.close_screen
          exit

        end
      end
    rescue
    end
  end
rescue
  Curses.close_screen
end
