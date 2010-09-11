#!/usr/bin/ruby
require 'net/https'
require 'open-uri'
require 'hpricot'
require 'fileutils'
require 'optparse'

module TracWiki
  class HashStruct < Hash
    def self.[](*hash)
      case hash.first
      when Hash
        super(*hash.first.map {|k, v| [k.to_sym, v] }.flatten(1))
      else
        i = 0
        super(*hash.map {|e| e = i % 2 == 0 ? e.to_sym : e; i += 1; e })
      end
    end
    
    def []=(key, value)
      super(key.to_sym, value)
    end
    
    def method_missing(sym, *args, &block)
      if has_key?(sym.to_sym)
        self[sym.to_sym]
      else
        super
      end
    end
  end
  
  DefaultConfiguration = HashStruct[
    :username => nil,
    :password => nil,
    :base_url => nil,
    :destination_path => '.',
    :pages => {},
    :categories => [],
    :wiki_title => "Trac Wiki Pages",
    :wiki_title_prefix => "Wiki",
    :no_index => false,
    :only_index => false,
  ].freeze
  
  class CLI
    attr_accessor :config
    
    def initialize
      self.config = DefaultConfiguration.dup
    end
    
    def run(*args)
      args = args.dup
      opts = OptionParser.new
      opts.banner = "Usage: trac-export-wiki [options] config.yaml"
      opts.on('-u', '--username USERNAME') {|username| config[:username] = username }
      opts.on('-p', '--password PASSWORD') {|password| config[:password] = password }
      opts.on('-b', '--base-url URL') {|url| config[:base_url] = url }
      opts.on('-t', '--wiki-title TITLE') {|title| config[:wiki_title] = title }
      opts.on('-T', '--wiki-title-prefix TITLE') {|title| config[:wiki_title_prefix] = title }
      opts.on('-i', '--only-index') { config[:only_index] = true }
      opts.on('-n', '--no-index') { config[:no_index] = true }
      opts.parse!(args)
      parse_from_yaml(args.first) if args.size > 0
      Exporter.new(config).export
    end

    private
    
    def parse_from_yaml(file)
      require 'yaml'
      config.update HashStruct[YAML.load_file(file)]
    end
  end
  
  class Exporter
    # common HTML elements to remove (expressed with css selectors)
    ELEMENTS_TO_REMOVE = ["html > head > link",
                          "html > head > style",
                          "html > head > script",
                          "html > body > script",
                          "div#banner",
                          "div#header",
                          "div#search",
                          "div#ctxtnav",
                          "div#metanav",
                          "div#mainnav",
                          "div.buttons",
                          "div#altlinks",
                          "div#footer",
                          "h3#tkt-changes-hdr",
                          "ul.tkt-chg-list"]
                          
    attr_accessor :config
    
    def initialize(config = DefaultConfiguration)
      self.config = config
    end
    
    def export
      write_pages unless config.only_index
      generate_index unless config.no_index
    end
    
    private

    def write_pages
      config.pages.each do |category, page_names|
        page_names.each do |page|
          print "Exporting \"" + page + "\"... "
          Page.new(page, category).export(config)
          puts "done."
        end
      end
    end

    def generate_index
      print "Exporting index..."
      index = <<-eof
        <html>
          <head>
            <title>#{config.wiki_title}</title>
          </head>
          <body>
            <h1>#{config.wiki_title}</h1>
      eof
      config.categories.each do |line|
        cat, name = *line
        index += "<h2>#{name}</h2>\n"
        index += "<ul>\n"
        config.pages.select {|k,v| k == cat }.each do |cat, docs|
          docs.each do |doc|
            fname = Page.new(doc, cat).filename
            index += "<li><a href='#{fname}'>#{doc}</a>\n"
          end
        end
        index += "</ul>\n"
      end
      index += <<-eof
          </body>
        </html>
      eof
      File.open('index.html', "w") { |f| f.write(index) }

      puts "done."
    end
  end
  
  class Page
    attr_accessor :page_title, :category, :filename, :config
    
    def initialize(page_title, category = nil)
      self.page_title = page_title
      self.category = category
      self.filename = File.join(*[category, page_title.gsub(/([a-z])([A-Z])/,'\1-\2').split(/\?/).first.downcase + '.html'].compact)
    end
    
    def export(config)
      self.config = config
      
      # load the wiki page
  	  doc = Hpricot(read_asset(page_title))

      # search for each element and remove it from the doc
      Exporter::ELEMENTS_TO_REMOVE.each { |e| doc.search(e).remove }

      # set title
      doc.search("html > head").at("title").inner_html = "#{config.wiki_title_prefix} - " + page_title.gsub(/([a-z])([A-Z])/,'\1 \2')

      # add link to css
      updir = "../" * category.split(/\//).size
      css = %Q(<link rel="stylesheet" type="text/css" href="#{updir}style.css" />)
      charset = %Q(<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />)
      doc.search("html > head").append(css + charset)

      # give toc's parent ol a class
      ol = doc.search("html > body > div.wiki-toc > ol").first
      ol.raw_attributes = ol.attributes.to_hash.merge('class' => 'top-most') unless ol.nil?

      # change the toc's li's class names
      doc.search("html > body > div.wiki-toc > ol").search("li.active").set(:class => 'toc') rescue nil

      # create category directory if it does not exist
      FileUtils.mkdir_p(File.dirname(filename)) rescue nil

      # find all images
      doc.search("//img").each do |img|
          imgfile = img.attributes['src']
          short_imgfile = File.basename(imgfile).split(/\?/).first

          # change image attribute in source
          img.raw_attributes = img.attributes.to_hash.merge("src" => File.join('images', short_imgfile))

          # make image directory
          outdir = File.join(File.dirname(filename), 'images')
          FileUtils.mkdir_p(outdir)

          # write image to file
          begin
            uri = URI.parse(config.base_url)
            contents = read_asset(imgfile, "#{uri.scheme}://#{uri.host}")
            File.open(File.join(outdir, short_imgfile), "wb") do |f|
                f.write(contents)
            end
          rescue OpenURI::HTTPError
          end
      end

      # write HTML to file
      File.open(filename, "w") { |f| f.write(doc.to_html) }
      print "wrote #{filename}... "
    rescue StandardError => bang
      print "(Oops! " + bang.message + ") "
    end
    
    private
    
    def read_asset(asset, base = nil)
      base ||= File.join(config.base_url, "wiki")
      open(File.join(base, asset), open_options).read
    end

    def open_options
      @open_options ||= config.username ? 
        {:http_basic_authentication => [config.username, config.password]} : {}
    end
  end
end 

class Net::HTTP
    alias :old_verify_mode :verify_mode=
    def verify_mode=(x) old_verify_mode(OpenSSL::SSL::VERIFY_NONE) end
end
