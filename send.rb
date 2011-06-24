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

class FaxDeService
    def initialize(wsdl_url)
        @client = Savon::Client.new do
            wsdl.document = wsdl_url
        end
    end

    def send(parameters)
        response = @client.request :send do
            soap.body = parameters
        end
        result = response.to_hash[:send_response]
        return_code = result[:return]
        abort(return_code) if return_code != "0"

        yield result
    end
end

settings = YAML.load_file('settings.yml')
fax_de = FaxDeService.new(settings['wsdl'])
fax_de.send default_send_parameters.merge({:schalter => 'TEST'}) do |result|
    doc = result[:check_doc_file]
    File.open('result.tiff', 'wb') { |f| f.write(Base64.decode64(doc)) }
end

exit if options[:dry_run]

fax_de.send default_send_parameters
