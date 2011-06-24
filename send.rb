#!/usr/bin/env ruby

require 'rubygems'
require 'savon'
require 'base64'
require 'yaml'
require 'optparse'

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

HTTPI.log = false
Savon.configure do |config|
    config.log = false
end

settings = YAML.load_file('settings.yml')
client = Savon::Client.new do
    wsdl.document = settings['wsdl']
end

name_of_file_to_send = ARGV[0]
path_to_file = File.join(Dir.pwd, name_of_file_to_send)
contents = File.open(path_to_file, 'rb') { |f| f.read }
encoded_contents = Base64.encode64(contents)

prefs = YAML.load_file('prefs.yml')
bw_iletter = 3
default_send_parameters = {
    :account => prefs['account'], 
    :password => prefs['password'],
    :job_art => bw_iletter,
    :empfaenger_nr => name_of_file_to_send,
    :send_filename1 => name_of_file_to_send,
    :send_file1 => encoded_contents
}

response = client.request :send do
    soap.body = default_send_parameters.merge({:schalter => 'TEST'})
end
result = response.to_hash[:send_response]
return_code = result[:return]
abort(return_code) if return_code != "0"

doc = result[:check_doc_file]
File.open('result.tiff', 'wb') { |f| f.write(Base64.decode64(doc)) }
exit if options[:dry_run]

response = client.request :send do
    soap.body = default_send_parameters
end
result = response.to_hash[:send_response]
return_code = result[:return]
abort(return_code) if return_code != "0"

