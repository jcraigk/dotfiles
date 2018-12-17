require 'pry'

Pry.config.theme = 'xoria256'
Pry.config.pager = false
Pry.config.editor = 'subl'

Pry.commands.alias_command 'c',  'continue'
Pry.commands.alias_command 's',  'step'
Pry.commands.alias_command 'n',  'next'
Pry.commands.alias_command 'f',  'finish'
Pry.commands.alias_command 'ss', 'show-source'
Pry.commands.alias_command 'xx', 'exit-program'

begin
  require 'awesome_print'
  AwesomePrint.pry!
rescue LoadError
  warn 'awesome_print not installed'
end

## Rails

Pry::Commands.command 'sql', 'Send sql over AR.' do |query|
  if ENV['RAILS_ENV'] || defined?(Rails)
    ap ActiveRecord::Base.connection.select_all(query).to_a
  else
    ap 'No rails env defined'
  end
end

def rr
  reload!
end
