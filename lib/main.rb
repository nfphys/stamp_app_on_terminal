require 'curses'
require 'timeout'
require_relative './worker.rb'

Curses.init_screen 
Curses.curs_set(0)

begin 
  win = Curses.stdscr

  win.setpos(0, 0)
  win.addstr("名前を入力してください\n")
  win.refresh
  win.addstr("名前: ")
  name = win.getstr

  worker = Worker.new(0, name)
  
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

    以下の数字を入力してください: 
    1. 出勤
    2. 退勤
    3. リセット
    4. 終了

    [LOG] #{log}
    TEXT
    )
    win.refresh # refresh わからん...

    begin 
      Timeout.timeout(0.1) do
        operation_number = win.getch.to_i 
        case operation_number 
        when 1
          worker = worker.start_work 
          log = "出勤しました"
        when 2 
          worker = worker.finish_work 
          log = "退勤しました"
        when 3 
          worker = worker.reset 
          log = "リセットしました"
        when 4 
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
