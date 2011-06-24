#!/usr/bin/env ruby

require 'rubygems'
require 'savon'
require 'base64'
require 'yaml'

prefs = YAML.load_file('prefs.yml')

HTTPI.log = false
Savon.configure do |config|
    config.log = false
end

client = Savon::Client.new do
    wsdl.document = "http://ccs.fax.de/xmlws3.exe/wsdl/IXMLWS2"
end

name_of_file_to_send = ARGV[0]
path_to_file = File.join(Dir.pwd, name_of_file_to_send)
contents = File.open(path_to_file, 'rb') { |f| f.read }
encoded_contents = Base64.encode64(contents)

response = client.request :send do
    bw_iletter = 3
    soap.body = {
        :account => prefs['account'], 
        :password => prefs['password'],
        :job_art => bw_iletter,
        :empfaenger_nr => name_of_file_to_send,
        :send_filename1 => name_of_file_to_send,
        :send_file1 => encoded_contents,
        :schalter => 'TEST',
    }
end

result = response.to_hash[:send_response]
return_code = result[:return]
p return_code

if return_code == "0"
    doc = result[:check_doc_file]
    File.open('result.tiff', 'wb') { |f| f.write(Base64.decode64(doc)) }
end
