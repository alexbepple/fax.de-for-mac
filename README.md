
Verwendung
==========

S/W-Brief versenden:

    sende <PDF-Datei>

Dies generiert auch einen Abzug in die Datei `preview.tiff`. Der Abzug spiegelt wider, wie Fax.de den Brief empfangen hat.

`sende -n <PDF>` generiert lediglich den Testabzug.

`sende` ist jeweils ein Alias, siehe Installationsanleitung.


Installation
============

1. Installiere Bundler.

        gem install bundler

1. Clone das Repository.
1. Installiere die Abhängigkeiten. Im neu erstellten Verzeichnis:

        bundle install --deployment

1. Kopiere die Konfigurationsdateien.

        mkdir ~/.fax.de
        cp account-sample.yml ~/.fax.de/account.yml
        cp settings.yml ~/.fax.de

1. Erstelle symbolischen Link für `send.wrapper.rb` in einem Verzeichnis auf dem `$PATH`.


Benachrichtigungen mit Growl
----------------------------

Diese Optionen müssen in den Systemeinstellungen für Growl aktiviert sein:

 * Listen for incoming notifications
 * Allow remote application registration


Development
===========

 * Uses Bundler for dependency management.
    * Bundles are stored in `vendor/bundle`.
