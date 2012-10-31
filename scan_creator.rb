
$:.unshift "#{File.dirname(__FILE__)}/lib"
require 'java'
require 'rtikam'
require 'lucenem'
require 'scan_logging'
require 'zip/zip'
require 'builder'
require 'hpricot'

include Logging

@index_path=""
@doc_base = ""
@index_folder = ""
@doc_root = ""
@def_root_folder = "C:/tmp/pdf"
@file_types  = "pdf"
@excluded_file_types  = %w[jpg]

def create_document(filename, content)
  doc = Document.new
  logger.info "adding (#{filename}) to index"
  doc.add Field.new("filename", filename, Field::Store::YES, Field::Index::ANALYZED)
  doc.add Field.new("content", content, Field::Store::YES, Field::Index::ANALYZED)  
  doc
end

def do_search(searcher, query_string)
  search_in = "content"
  m = query_string.match(/^(filename|content):.*/) 
  if m 
    query_string = query_string.split(':')[1]
    search_in = m[1] 
    logger.info "=="
  end  

  logger.info "== will search in : #{search_in}"
  parser = QueryParser.new(Version::LUCENE_30, search_in, StandardAnalyzer.new(Version::LUCENE_30))
  query = parser.parse(query_string) rescue nil
  hits_per_page = 10
  collector = TopScoreDocCollector.create(5 * hits_per_page, false)
  searcher.search(query, collector)
  hits = collector.top_docs.scoreDocs
  hit_count = collector.get_total_hits    
  if hit_count.zero?
    logger.info "No matching documents."
  else

    page = get_html_basic
    page.gsub!('#query#', query_string)

    logger.info "%d total matching documents" % hit_count
    logger.info "#{hits.size} Hits for %s were found in quotes by:" % query_string    
    links = []
    hits.each_with_index do |score_doc, i|
      doc_id = score_doc.doc
      doc_score = score_doc.score
      # logger.info "doc_id: %s \t score: %s" % [doc_id, doc_score]      
      doc = searcher.doc(doc_id)
      f = doc.get("filename").split('.')
      #ff=f[0..-2].join('.')
      ff=doc.get("filename")
      links << "<li>Score = %0.02f <a href=file://%s>%s</a></li>" % [doc_score.to_f, ff, File.basename(ff)]
      logger.info "score %.02f Filename :<%s/%s>" % [doc_score.to_f, @doc_base, ff ]      
    end
    page.gsub!('#content#', links.join('<br />'))
    fh = File.open("query_results.html", 'w') 
    fh.write page
    fh.close
    logger.info "calling the browser"
    system('query_results.html')    

  end
end

def rtika_parse(file_name)
	output = {}
	result = RTika::FileParser.parse(file_name, {:remove_boilerplate=>false})  	
	output ['content'] = result.content 
	return output
end
 
def create_index_all_supported_types

  begin

    logger.info "== index folder is : %s" % @index_folder
    idx = Lucene::Store::FSDirectory.open(java.io.File.new(@index_folder))
    stats = {}
    stats['no_content'] = 0
    stats['total'] = 0
    writer  = IndexWriter.new(idx, StandardAnalyzer.new(Version::LUCENE_30), Lucene::Index::IndexWriter::MaxFieldLength::UNLIMITED)    
    logger.info "starting to index : #{@doc_root}"
    count = 0
    logger.info "chdir to the folder : #{@doc_root}"
    Dir.chdir(@doc_root)

    Dir["#{@doc_root}/**/*{#{@file_types}}"] .each do |f| 
      logger.info "==> #{f}"
      # next
      #output = rtika_parse(File.join(@doc_root,f))	
      output = rtika_parse(f)	
      filename = f
      logger.info "now treating file : <#{f}>"
      if output['content'] != nil || output['content'] == ""   
  	    writer.add_document(create_document(filename, output['content']))
        stats['total'] += 1
      else
        stats['no_content'] += 1
      end
    end
    t=stats['total']
    nc=stats['no_content']
    logger.info "Index creation statistics :"
    logger.info "Index folder : <#{@index_folder}>"
    logger.info "Document Root: <#{@doc_root}>"  
    logger.info "Files Total indexed   : #{t.to_i}"
    logger.info "Files with no content : #{nc.to_i} "
    writer.optimize
    writer.close
    dirsize = 0
    Dir["#{@index_folder}/*"].each do |f| dirsize +=  File.size(f) end
    logger.info "Total size of index is : #{index_folder_size} KB "
    idx
    return true
  rescue
    logger.info "Error while creating the index : %s" % $!
    return false
  end
end

def index_folder_size

  dirsize = 0
  Dir["#{@index_folder}/*"].each do |f| dirsize +=  File.size(f) end
  #logger.info "Total size of index is : #{dirsize/1024} KB "
  return dirsize/1024 if dirsize
end

def get_root_folder
  # puts  "inside get_root_folder : (#{ARGV[1]})"
  if !ARGV[1]
    logger.warn  "ARGV is empty"

    logger.info "root_folder will be : #{@def_root_folder}"
    doc_base = @def_root_folder
    
  else
    logger.info  "ARGV1 is NOT empty"
    doc_base = ARGV[1] 
  end 
end 

def get_html_basic
  return "
  <!DOCTYPE html>
  <html>
  <body>
  <h1>Documents matching query <#query#></h1>
  <ul>
  <#content#>  
  </ul>
  </body>
  </html>"
end

def main

  if ARGV.size == 0
    logger.info "Entering Pure search mode" 
    logger.info "please specify the root folder"
    @doc_base=get_root_folder
    @index_folder = File.join(@doc_base,'test.index')
    
    # now reopen the index (this simulated the client side => search function
    index = Lucene::Store::FSDirectory.open(java.io.File.new(@index_folder))
    logger.info "index folder is <#{@index_folder}>"
    logger.info "index folder size : #{index_folder_size} kb"

    searcher = IndexSearcher.new(index)

    query = ""

    begin
      puts "type your search query (. to quit):" 
      query=gets().chomp.gsub(/^\*/,"").gsub("%","").gsub("?","")
      puts "searching for : <#{query}> " unless query == '.'
      next if query.size == 0
      do_search(searcher,query) if query != "."      
    end while query != "."    
    searcher.close
    exit
  end

  @base_dir = Dir.pwd()
  
  if ARGV[0] == '-v' || ARGV[0] == '-version'
    v = 'unknown version'
    v = File.open('scan_creator.version').read rescue nil
    puts "scan creator version #{v}"
    exit 0
  end

  doc_base=get_root_folder
  logger.info "Root folder is set to :  #{doc_base}"
  if File.exist?(doc_base)
    logger.info "Root folder <%s> exists" % doc_base
    @doc_root=doc_base
    @index_folder = File.join(doc_base,'test.index')
    if File.exists?(@index_folder)
      logger.warn "index folder #{@index_folder} created before ! removing all files from within"
      Dir["#{@index_folder}/*"].each {|f| FileUtils.rm f}        
    end        
  else      
    logger.warn "Root folder <%s> DOES NOT EXIST" % doc_base
    exit 1
  end

  if ARGV[0].include? 'c' 
    logger.info "Creating Index " 
    create_index_all_supported_types 
  end
end

#main script

logger.info "scan_creator started"

Dir["jffi*.tmp"].each do |f|
  FileUtils.rm f rescue nil
end

main()