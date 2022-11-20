# frozen_string_literal: true
require 'pry'

# pry
Pry.config.completer = nil
Pry.config.editor = 'subl'
Pry.config.pager = false
Pry.config.theme = 'xoria256'

if defined?(PryDebugger)
  Pry.commands.alias_command 'cc', 'continue'
  Pry.commands.alias_command 'ss', 'step'
  Pry.commands.alias_command 'nn', 'next'
  Pry.commands.alias_command 'ff', 'finish'
end
Pry.commands.alias_command 'ss', 'show-source'
Pry.commands.alias_command 'xx', 'exit-program'

# awesome_print
begin
  require 'awesome_print'
  AwesomePrint.pry!
rescue LoadError
  warn 'awesome_print not installed'
end
