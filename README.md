# Trac Wiki Exporter

## Synopsis

Exports wiki pages in Trac as HTML pages organized in categories for easy
local viewing.

## Installing

This script requires [Ruby](http://ruby-lang.org). You can install it for Linux
or Windows from the above link, or use your OS's package manager to install it.
Once it is installed, call the following command:

    $ [sudo] gem install trac-export-wiki
    
## Using

To use this script, you need to create a `config.yaml` file that tells the
exporter which pages you want to export under which categories. You can
see a sample config.yaml file in the "examples" directory. Once you've
created your configuration file, you can call the script with:

    $ trac-export-wiki config.yaml
    
This will download the wiki pages from your site into your current directory.
If you want to put your files in a `docs` directory, make sure to cd there
first:

    $ mkdir docs
    $ cd docs
    $ trac-export-wiki ../config.yaml
    
You can specify some parameters on the command-line, see `trac-export-wiki --help`
for a list of options. Specifically, you may want to only regenerate the index
page, or not generate the index page. This is done with `-i` or `-n` respectively.

## License & Author

This library is written by Loren Segal and released under the MIT license.
See the `LICENSE` file attached with this archive.