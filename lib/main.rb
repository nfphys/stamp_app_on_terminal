require 'timeout'
require_relative './worker.rb'

id = 0

puts "名前を入力してください:"
print "名前:"
name = gets.chomp
printf "\n"

worker = Worker.new(id, name)

loop do
  printf "勤務状況:#{worker.status}\n"
  printf "勤務時間:#{worker.working_hours}\n"
  printf "勤務開始時刻:#{worker.started_work_at}\n"
  printf "勤務終了時刻:#{worker.finished_work_at}\n"
  printf "\n"
  printf "数字を入力してください:\n"
  printf "1. 出勤\n"
  printf "2. 退勤\n"
  printf "3. リセット\n"
  printf "\n"

  t = 1
  begin 
    Timeout.timeout(t) do 
      n = gets.to_i 
      case n 
      when 1
        worker = worker.start_work 
      when 2 
        worker = worker.finish_work 
      when 3
        worker = worker.reset
      end
      printf "\e[11A\r"
    end
  rescue Timeout::Error 
    printf "\e[10A\r"
  end
end

