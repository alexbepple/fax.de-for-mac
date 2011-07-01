require 'savon'
require 'base64'

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
        @fax_de.send to_hash do
            yield
        end
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

