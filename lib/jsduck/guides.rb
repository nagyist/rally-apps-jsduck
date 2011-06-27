require 'jsduck/jsonp'
require 'jsduck/logger'
require 'fileutils'

module JsDuck

  # Reads in guides and converts them to JsonP files
  class Guides
    def initialize(formatter)
      @guides = []
      @formatter = formatter
    end

    # Looks for guide in each subdir of given directory.
    def parse_dir(guides_dir)
      Dir.glob(guides_dir + "/*").each do |dir|
        if File.directory?(dir)
          parse_guide(dir)
        end
      end
    end

    def parse_guide(dir)
      guide_file = dir + "/README.md"
      unless File.exists?(guide_file)
        return Logger.instance.warn("README.md not found in #{dir}")
      end

      Logger.instance.log("Parsing guide #{guide_file} ...")
      markdown = IO.read(guide_file)
      name = File.basename(dir)
      # Treat the first line of file as title
      title = markdown.match(/^([^\n]*?)(\r?\n|$)/)[1],

      @formatter.doc_context = {:filename => guide_file, :linenr => 0}
      html = @formatter.format(markdown)
      html.gsub!(/<img src="/, "<img src=\"guides/#{name}/")

      @guides << {
        :dir => dir,
        :name => name,
        :title => title,
        :icon => File.exists?(dir+"/icon.png") ? dir+"/icon.png" : nil,
        :html => html,
      }
    end

    # Writes all guides to given dir in JsonP format
    def write(dir)
      # Skip it all when we have no guides
      FileUtils.mkdir(dir) if @guides.length > 0

      @guides.each do |guide|
        out_dir = dir+"/"+guide[:name]
        FileUtils.cp_r(guide[:dir], out_dir)
        # Write the JsonP file and remove the original Markdown file
        JsonP.write(out_dir+"/README.js", guide[:name], {:guide => guide[:html]})
        FileUtils.rm(out_dir + "/README.md")
      end
    end

  end

end
