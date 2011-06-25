
require 'rubygems'
require 'ruby-growl'

class FaxDeGrowlNotifier
    def initialize
        @growl = Growl.new "127.0.0.1", "fax.de", ['']
    end
    def notify(message)
        @growl.notify '', 'Fax.de', message
    end
end
