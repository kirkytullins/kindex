module Lucene
  module Store
    include_package 'org.apache.lucene.store'
  end
  module Index
    include_package 'org.apache.lucene.index'
  end
  module Doc
    include_package 'org.apache.lucene.document'
  end
  module Search
    include_package 'org.apache.lucene.search'
  end

  module TokenAttributes
    include_package 'org.apache.lucene.analysis.tokenattributes'
  end

  StandardTokenizer = org.apache.lucene.analysis.standard.StandardTokenizer
  Version = org.apache.lucene.util.Version
end

java_import org.apache.lucene.analysis.standard.StandardAnalyzer
java_import org.apache.lucene.document.Document
java_import org.apache.lucene.document.Field
java_import org.apache.lucene.index.IndexWriter
java_import org.apache.lucene.index.IndexReader
java_import org.apache.lucene.queryParser.ParseException
java_import org.apache.lucene.queryParser.QueryParser
java_import org.apache.lucene.store.RAMDirectory
java_import org.apache.lucene.util.Version

java_import org.apache.lucene.search.IndexSearcher
java_import org.apache.lucene.search.TopScoreDocCollector

