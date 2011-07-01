#!/usr/bin/env ruby

require 'pathname'
dir = File.dirname(Pathname.new(__FILE__).realpath)

require 'yaml'
require 'optparse'

require 'fax_de'
require 'fax_de_growl'

options = {}
options_parser = OptionParser.new do |opts|
    options[:dry_run] = false
    opts.on('-n', '--dry-run', 'Create a preview, but do not actually send the letter.') do
        options[:dry_run] = true
    end
    opts.on('-h', '--help', 'Guess what.') do 
        puts opts
        exit
    end
end
options_parser.parse!


notifier = FaxDeGrowlNotifier.new

account_prefs = YAML.load_file(File.join(dir, 'account.yml'))
account = Account.new account_prefs['account'], account_prefs['password']

settings = YAML.load_file(File.join(dir, 'settings.yml'))
fax_de = FaxDeService.new(settings['wsdl'], account)

name_of_file_to_send = ARGV[0]
path_to_file = File.join(Dir.pwd, name_of_file_to_send)
contents = File.open(path_to_file, 'rb') { |f| f.read }

letter = FaxDeLetter.new(fax_de, name_of_file_to_send, contents)

letter.generate_preview do |preview|
    File.open('result.tiff', 'wb') { |f| f.write(preview) }
    notifier.notify 'Generated preview file.'
end
exit if options[:dry_run]
letter.send do
    notifier.notify "Sent ‘#{name_of_file_to_send}’."
end
