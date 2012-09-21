require 'rubygems'
require 'rake'
require 'echoe'

Echoe.new('innowhite', '1.0.0') do |p|
  p.description    = "Eway Api"
  p.url            = "http://github.com/bainur/eway"
  p.author         = "bainur"
  p.email          = "inoe.bainur@gmail.com"
  p.ignore_pattern = ["tmp/*", "script/*"]
  p.development_dependencies = []
end

Dir["#{File.dirname(__FILE__)}/tasks/*.rake"].sort.each { |ext| load ext }
