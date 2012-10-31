%w[rubygems java logger].each { |lib| require lib }

module Logging 
  # This is the magical bit that gets mixed into your classes 
  def logger 
    Logging.logger 
  end 
 
  # Global, memoized, lazy initialized instance of a logger 
  def self.logger
    if ! @log
      log_name = Time.now.strftime("delex_creator_%Y_%m_%d_%H_%M.log")
      Java::OrgApacheLog4j.BasicConfigurator.configure()
      @log = Java::OrgApacheLog4j::Logger.getRootLogger()
      @log.get_all_appenders.first.set_layout Java::OrgApacheLog4j::PatternLayout.new("%8r [%p] %m%n")
      @log.add_appender Java::OrgApacheLog4j::FileAppender.new(Java::OrgApacheLog4j::PatternLayout.new("%8r [%p] %m%n"),log_name,false)
      @log.setLevel(Java::OrgApacheLog4j::Level::INFO)
      @log.info 'JOB START : ' + Time.now.to_s
      @log.info 'logging to file : ' + log_name
      # @logger = Logger.new(STDOUT) 
      # @logger.datetime_format = '%Y-%m-%d %H:%M:%S '
    end
    @log
  end 

end 