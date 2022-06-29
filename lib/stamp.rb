require 'mysql2'
require 'curses'
require 'timeout'
require_relative './stamp/worker.rb'

module Stamp
end

require_relative './stamp/create_database.rb'

def Stamp::stamp(host: 'localhost', username: 'root', password: )
  client = 
    Mysql2::Client.new(
      host: host,
      username: username,
      password: password
    )

  Curses.init_screen 
  Curses.curs_set(0) # invisible cursor

  begin 
    win = Curses.stdscr

    # 名前の入力
    win.setpos(0, 0)
    win.addstr("名前を入力してください\n")
    win.addstr("名前: ")
    name = win.getstr

    worker = Worker.load_from_database(client, name)
    
    log = ""

    loop do 
      win.clear
      win.setpos(0, 0)
      win.addstr(
        <<~TEXT
        ようこそ、#{name}さん

        勤務状況: #{worker.status}

        勤務時間: #{worker.working_hours}
        勤務開始時刻: #{worker.started_work_at}
        勤務終了時刻: #{worker.finished_work_at}

        休憩時間: #{worker.breaking_hours}
        休憩回数: #{worker.started_break_at.size}

        コマンド: 
        出勤(s) 退勤(f) 休憩(b) 再開(r) 終了(q)

        [LOG] #{log}
        TEXT
      )
      win.refresh

      begin 
        Timeout.timeout(0.1) do
          command = win.getch
          case command
          when 's' # 出勤
            if worker.finished_work?
              log = "s: 既に退勤しています"
              break 
            end
            if worker.started_work?
              log = "s: 既に出勤しています"
              break 
            end
            worker = worker.start_work(client)
            log = "s: 出勤しました"

          when 'f' # 退勤
            unless worker.started_work?
              log = "f: まだ出勤していません"
              break 
            end
            if worker.finished_work?
              log = "f: 既に退勤しています"
              break 
            end
            worker = worker.finish_work(client)
            log = "f: 退勤しました"

          when 'b' # 休憩
            unless worker.started_work?
              log = "b: まだ出勤していません"
              break 
            end
            if worker.finished_work?
              log = "b: 既に退勤しています"
              break
            end
            if worker.breaking?
              log = "b: 既に休憩しています"
              break 
            end
            worker = worker.start_break(client)
            log = "b: 休憩を開始しました"

          when 'r' # 再開
            unless worker.started_work?
              log = "r: まだ出勤していません"
              break 
            end
            if worker.finished_work?
              log = "r: 既に退勤しています"
              break
            end
            if worker.working?
              log = "r: まだ休憩していません"
              break 
            end
            worker = worker.finish_break(client)
            log = "r: 休憩を終了しました"

          when 'q' # 終了
            Curses.close_screen
            return 
          end
        end
      rescue
      end
    end
  rescue
    Curses.close_screen
  end
end
