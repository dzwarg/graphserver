require 'webrick'
require 'xmlrpc/server.rb'
require 'graph.rb'
require 'optparse'

class Link
  def to_xml
    "<link/>"
  end
end

class Street
  def to_xml
    "<street name='#{name}' length='#{length}' />"
  end
end

class TripHopSchedule
  def to_xml
    "<triphopschedule/>"
  end
end

class State
  def to_xml
    ret = "<state "
    self.to_hash.each_pair do |name, value|
      ret << "#{name}='#{value.to_s}' "
    end
    ret << "/>"
  end
end

class Vertex
  def to_xml
    "<vertex label='#{label}'/>"
  end
end

class Edge
  def to_xml
    ret = "<edge>"
    ret << payload.to_xml
    ret << "</edge>"
  end
end

OPTIONS = { :port => 3003 }

ARGV.options do |opts|
  script_name = File.basename($0)
  opts.banner = "Usage: ruby #{script_name} [options]"

  opts.separator ""

  opts.on("-p", "--port=port", Integer,
          "Runs Rails on the specified port.",
          "Default: 3003") { |v| OPTIONS[:port] = v }

  opts.on("-h", "--help",
          "Show this help message.") { puts opts; exit }

  opts.parse!
end

class Graphserver  
  attr_reader :gg 

  def parse_init_state request
    State.new( (request.query['time'] or Time.now) ) #breaks without the extra parens
  end 

  def initialize
    @gg = Graph.create #horrible hack

    @server = WEBrick::HTTPServer.new(:Port => OPTIONS[:port])

    @server.mount_proc( "/" ) do |request, response|
      ret = ["Graphserver Web API"]
      ret << "shortest_path?from=FROM&to=TO"
      ret << "all_vertex_labels"
      ret << "outgoing_edges?label=LABEL"
      response.body = ret.join("\n")
    end

    @server.mount_proc( "/shortest_path" ) do |request, response|
      init_state = parse_init_state( request )
      vertices, edges = @gg.shortest_path( request.query['from'], request.query['to'], init_state )

      p vertices
      if vertices.class == Graph then p vertices.edges end

      ret = []
      ret << "<?xml version='1.0'?>"
      ret << "<route>"
      ret << vertices.shift.to_xml
      edges.each do |edge|
        ret << edge.to_xml
        ret << vertices.shift.to_xml
      end
      ret << "</route>"
      response.body = ret.join
    end

    @server.mount_proc( "/all_vertex_labels" ) do |request, response|
      vlabels = []
      vlabels << "<?xml version='1.0'?>"
      vlabels << "<labels>"
      @gg.vertices.each do |vertex|
        vlabels << "<label>#{vertex.label}</label>"
      end
      vlabels << "</labels>"
      response.body = vlabels.join
    end

    @server.mount_proc( "/outgoing_edges" ) do |request, response|
      vertex = @gg.get_vertex( request.query['label'] )
      ret = []
      ret << "<?xml version='1.0'?>"
      ret << "<edges>"
      vertex.each_outgoing do |edge|
        ret << "<edge>"
        ret << "<dest>#{edge.to.to_xml}</dest>"
        ret << "<payload>#{edge.payload.to_xml}</payload>"
        ret << "</edge>"
      end
      ret << "</edges>"
      response.body = ret.join
    end

  end

  def database_params= params
    begin
      require 'postgres'
    rescue LoadError
      @db_params = nil
      raise
    end

    begin
      #check if database connection works
      conn = PGconn.connect( params[:host],
                             params[:port],
                             params[:options],
                             params[:tty],
                             params[:dbname],
                             params[:login],
                             params[:password] )
      conn.close
    rescue PGError
      @db_params = nil
      raise
    end

    @db_params = params
    return true
  end

  def connect_to_database
    unless @db_params then return nil end

    PGconn.connect( @db_params[:host],
                    @db_params[:port],
                    @db_params[:options],
                    @db_params[:tty],
                    @db_params[:dbname],
                    @db_params[:login],
                    @db_params[:password] )
  end

  #may return nil if postgres isn't loaded, or the connection params aren't set
  def conn
    #if @conn exists and is open
    if @conn and begin @conn.status rescue PGError false end then
      return @conn
    else
      return @conn = connect_to_database
    end
  end

  def start
    trap("INT"){ @server.shutdown }
    @server.start
  end

end