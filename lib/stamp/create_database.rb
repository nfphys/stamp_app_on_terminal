def Stamp::create_database(host: 'localhost', username: 'root', password: )
  client = 
    Mysql2::Client.new(
      host: host,
      username: username,
      password: password
    )

  begin 
    client.query('CREATE DATABASE stamp_app_on_terminal')
  rescue Mysql2::Error => e 
    puts e.message 
  end

  client.query('USE stamp_app_on_terminal')

  begin 
    client.query(
      <<~TEXT
      CREATE TABLE users (
        id INT AUTO_INCREMENT, 
        name TEXT, 
        PRIMARY KEY (id)
      )
      TEXT
    )
  rescue Mysql2::Error => e 
    puts e.message 
  end

  begin 
    client.query(
      <<~TEXT
      CREATE TABLE work_data (
        id INT AUTO_INCREMENT, 
        started_work_at DATETIME, 
        finished_work_at DATETIME, 
        user_id INT, 
        PRIMARY KEY (id)
      )
      TEXT
    )
  rescue Mysql2::Error => e 
    puts e.message 
  end

  begin 
    client.query(
      <<~TEXT
      CREATE TABLE break_data (
        id INT AUTO_INCREMENT, 
        started_break_at DATETIME, 
        finished_break_at DATETIME, 
        user_id INT, 
        work_data_id INT, 
        PRIMARY KEY (id)
      )
      TEXT
    )
  rescue Mysql2::Error => e 
    puts e.message 
  end
end