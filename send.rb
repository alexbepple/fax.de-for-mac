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

class Account
    attr :account, :password

    def initialize(account, password)
        @account = account
        @password = password
    end

    def to_hash
        {:account => @account, :password => @password}
    end
end

class FaxDeLetter
    def initialize(fax_de, name, contents)
        @fax_de = fax_de
        @name = name
        @contents = Base64.encode64(contents)
    end
    
    def generate_preview
        @fax_de.send to_hash.merge({:schalter => 'TEST'}) do |result|
            doc = result[:check_doc_file]
            yield Base64.decode64(doc)
        end
    end

    def send
        @fax_de.send to_hash
    end

    def to_hash
        bw_iletter = 3
        {
            :job_art => bw_iletter,
            :empfaenger_nr => @name,
            :send_filename1 => @name,
            :send_file1 => @contents
        }
    end
end

class FaxDeService
    def initialize(wsdl_url, account)
        HTTPI.log = false
        Savon.configure do |config|
            config.log = false
        end

        @client = Savon::Client.new do
            wsdl.document = wsdl_url
        end

        @account = account
    end

    def send(parameters)
        account = @account
        response = @client.request :send do
            soap.body = account.to_hash.merge(parameters)
        end
        result = response.to_hash[:send_response]
        return_code = result[:return]
        abort(return_code) if return_code != "0"

        yield result
    end
end

account_prefs = YAML.load_file('account.yml')
account = Account.new account_prefs['account'], account_prefs['password']

settings = YAML.load_file('settings.yml')
fax_de = FaxDeService.new(settings['wsdl'], account)

name_of_file_to_send = ARGV[0]
path_to_file = File.join(Dir.pwd, name_of_file_to_send)
contents = File.open(path_to_file, 'rb') { |f| f.read }

letter = FaxDeLetter.new(fax_de, name_of_file_to_send, contents)

letter.generate_preview do |preview|
    File.open('result.tiff', 'wb') { |f| f.write(preview) }
end
exit if options[:dry_run]
letter.send
