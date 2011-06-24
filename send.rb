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
    def initialize(fax_de, args={})
        @fax_de = fax_de
        @account = args[:account]
        @name = args[:name]
        @contents = Base64.encode64(args[:contents])
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
        prefs = YAML.load_file('prefs.yml')
        bw_iletter = 3
        @account.to_hash.merge({
            :job_art => bw_iletter,
            :empfaenger_nr => @name,
            :send_filename1 => @name,
            :send_file1 => @contents
        })
    end
end

class FaxDeService
    def initialize(wsdl_url)
        HTTPI.log = false
        Savon.configure do |config|
            config.log = false
        end

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

prefs = YAML.load_file('prefs.yml')
account = Account.new prefs['account'], prefs['password']

name_of_file_to_send = ARGV[0]
path_to_file = File.join(Dir.pwd, name_of_file_to_send)
contents = File.open(path_to_file, 'rb') { |f| f.read }

letter = FaxDeLetter.new(fax_de, :account => account, :name => name_of_file_to_send, :contents => contents)

letter.generate_preview do |preview|
    File.open('result.tiff', 'wb') { |f| f.write(preview) }
end
exit if options[:dry_run]
letter.send
