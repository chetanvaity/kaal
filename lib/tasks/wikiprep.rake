# encoding: UTF-8

require 'util.rb'
require 'wikipreputil.rb'

namespace :wikiprep do
  desc "Read the wikiprep hgw.xml file and create article files"
  task :create_articles, [:wikiprep_file,:out_dir] do |t, args|
    wu = WikiprepUtil.instance
    wpfname = args.wikiprep_file
    outdir = args.out_dir

    wu.make_pages2(wpfname, outdir)    
  end

end # namespace :yago
