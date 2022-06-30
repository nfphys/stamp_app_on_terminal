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
    Curses.noecho

    worker = Worker.load_from_database(client, name)
    
    log = ""

    command = nil
    confirmed = false

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
          if command 
            case command
            when 's'
              win.addstr('出勤しますか？(Y/n)')
            when 'f'
              win.addstr('退勤しますか？(Y/n)')
            when 'b'
              win.addstr('休憩しますか？(Y/n)')
            when 'r'
              win.addstr('再開しますか？(Y/n)')
            end

            yes_or_no = win.getch 
            case yes_or_no 
            when 'Y'
              confirmed = true
            when 'n'
              confirmed = false 
              command = nil
            end
          end

          command = win.getch if command.nil?
          case command
          when 's' # 出勤
            if worker.finished_work?
              log = "s: 既に退勤しています"
              command = nil
              break 
            end
            if worker.started_work?
              log = "s: 既に出勤しています"
              command = nil
              break 
            end
            break unless confirmed
            unless confirmed 
              command = nil
              break 
            end
            worker = worker.start_work(client)
            command = nil
            confirmed = false 
            log = "s: 出勤しました"

          when 'f' # 退勤
            unless worker.started_work?
              log = "f: まだ出勤していません"
              command = nil
              break 
            end
            if worker.finished_work?
              log = "f: 既に退勤しています"
              command = nil
              break 
            end
            break unless confirmed
            worker = worker.finish_work(client)
            command = nil
            confirmed = false 
            log = "f: 退勤しました"

          when 'b' # 休憩
            unless worker.started_work?
              log = "b: まだ出勤していません"
              command = nil
              break 
            end
            if worker.finished_work?
              log = "b: 既に退勤しています"
              command = nil
              break
            end
            if worker.breaking?
              log = "b: 既に休憩しています"
              command = nil
              break 
            end
            break unless confirmed
            worker = worker.start_break(client)
            command = nil
            confirmed = false 
            log = "b: 休憩を開始しました"

          when 'r' # 再開
            unless worker.started_work?
              log = "r: まだ出勤していません"
              command = nil
              break 
            end
            if worker.finished_work?
              log = "r: 既に退勤しています"
              command = nil
              break
            end
            if worker.working?
              log = "r: まだ休憩していません"
              command = nil
              break 
            end
            break unless confirmed
            worker = worker.finish_break(client)
            command = nil
            confirmed = false 
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
