Gem::Specification.new do |s|
  s.name        = 'stamp'
  s.version     = '0.0.0'
  s.executables << 'stamp'
  s.executables << 'create_database'
  s.summary     = 'Stamp App on Terminal'
  s.description = 'Records your daily working hours.'
  s.authors     = ['Fumiya Nakamura']
  s.email       = 'nfphys@gmail.com'
  s.files       = ['lib/stamp.rb', 'lib/stamp/worker.rb', 'lib/stamp/timer.rb']
  s.homepage    = 'https://github.com/nfphys/stamp_app_on_terminal'
  s.license     = 'MIT'
end