require "optparse"
require "open3"
require "colorize"

INIT_COMMAND = "rrinit"
PUSH_COMMAND = "rrpush"
PULL_COMMAND = "rrpull"

class RemoteInfo
    FILENAME = ".reminfo"
    
    attr_accessor   :host
    attr_accessor   :port
    attr_accessor   :user
    attr_accessor   :path
    attr_accessor   :netns
    attr_accessor   :owner
    attr_accessor   :operations
    
    def initialize
        @netns = nil
        @owner = nil
        
        @port = nil
        @user = nil
        
        @operations = "rw"
    end
    
    def self.load(folder=".")
        rinfo = RemoteInfo.new
        rinfo.read_info(folder)
        return rinfo
    end
    
    def self.filename(folder)
        return File.join(folder, FILENAME)
    end
    
    def can_pull?
        return @operations.include? "r"
    end
    
    def can_push?
        return @operations.include? "w"
    end
    
    def read_info(folder)
        info = File.read(File.join(folder, FILENAME))
        
        rows = info.split "\n"
        rows.each do |r|
            key, value = *r.split("\t")
            
            key = key.strip
            value = value.strip
            
            case key
            when "host"
                @host = value
            when "port"
                @port = value
            when "user"
                @user = value
            when "path"
                @path = value
            when "netns"
                @netns = value
            when "owner"
                @owner = value
            when "operations"
                @operations = value
            end
        end
    end
    
    def save_info(to=".")
        content = ""
        content += "host\t#@host\n"
        content += "port\t#@port\n"                 if @port
        content += "user\t#@user\n"                 if @user
        content += "path\t#@path\n"
        content += "netns\t#@netns\n"               if @netns
        content += "owner\t#@owner\n"               if @owner
        content += "operations\t#@operations\n"
        
        dest = to ? File.join(to, FILENAME) : FILENAME
        
        File.write dest, content
    end
    
    def self.unlock_all(local)
        self.lock_all(local, true) {}
    end
    
    def self.lock_all(local, prevent_write=true)
         if (prevent_write)
            FS.each_remote_info(local) do |rinfo|
                OS.run "chmod -w \"#{rinfo}\""
            end
        end
        
        yield
        
        if (prevent_write)
            FS.each_remote_info(local) do |rinfo|
                OS.run "chmod +w \"#{rinfo}\""
            end
        end
    end
end

class FS
    def self.each_folder(dir, recursive=true)
        queue = ["."]
        visited = []
        while queue.size > 0
            current = queue.shift
            
            yield current
            
            if recursive
                Dir.entries(current).each do |entry|
                    next if [".",".."].include? entry
                    to_queue = (current == "." ? entry : File.join(current, entry))
                    
                    queue.push to_queue if FileTest.directory? to_queue
                end
            end

            queue -= visited
            visited.push current
        end
    end
    
    def self.each_remote_info(dir)
        self.each_folder(dir) do |folder|
            filename = File.join(folder, RemoteInfo::FILENAME)
            yield filename if FileTest.exists? filename
        end
    end
end

class ScpUtils
    def self.remote(local, file)
        user = file.user
        port = file.port
        host = file.host
        path = file.path
        
        userstring = user ? user + "@" : ""
        
        remotepath = path
        remotepath = File.join(remotepath, local) if local && local != "."
        
        result = "#{userstring}#{host}:#{remotepath}"
    end
    
    def self.local(*candidates)
        candidates.each do |c|
            return c if c
        end
        
        return "."
    end
    
    def self.scp(from, to, dir, port=nil)
        dirstring = dir ? "-r" : ""
        portstring = port ? "-P " + port : ""
        
        return "scp #{portstring} #{dirstring} \"#{from}\" \"#{to}\""
    end
end

class CmdParser
    @@data = {}
    @@bindings = {}
    
    def self.opt(key)
        return @@data[key]
    end
    
    def self.set(key, value)
        @@data[key] = value
    end
    
    def self.setup(cmd, *args)
        parser = OptionParser.new do |opts|
            opts.banner = "Usage: #{cmd} [options] #{args.join " "}"
            
            @@opts = opts
            yield opts
            @@opts = nil
            
            opts.on("-v", "--verbose", "Writes a lot of information") do
                CmdParser.set :verbose, true
            end
            
            opts.on("-h", "--help", "Prints this help") do
                puts opts
                exit
            end
        end
        
        parser.parse! ARGV
        
        arguments = {}
        for i in 0...args.size
            arguments[args[i]] = ARGV[i]
        end
        
        return arguments
    end
    
    def self.autoset_flag(short, long, description, flag, incompatibles=[])
        @@bindings[flag] = short
        @@opts.on(short, long, description) do
            incompatibles.each do |incompatible|
                CmdParser.assert_not_set incompatible, short, @@bindings[incompatible]
            end
            
            CmdParser.set flag, true
        end
    end
    
    def self.autoset_param(short, long, description, flag, incompatibles=[])
        @@bindings[flag] = short
        @@opts.on(short, long, description) do |v|
            incompatibles.each do |incompatible|
                CmdParser.assert_not_set incompatible, short, @@bindings[incompatible]
            end
            
            CmdParser.set flag, v
        end
    end
    
    def self.assert
        error_message = yield
        if error_message
            puts error_message
            exit
        end
    end
    
    def self.assert_not_set(forbidden_key, actual_param, forbidden_param, message="incompatible commands")
        if CmdParser.opt(forbidden_key) != nil
            puts "Do not use #{forbidden_param} with #{actual_param} (#{message}). Aborting."
            exit
        end
    end
end

class ConsoleRunner
    def remove_file(file)
        File.unlink file
    end
    
    def username
        return `echo $USER`.chomp
    end
    
    def run(cmd)
        vputs "Executing command: #{cmd}"
        stdout, stderr, status = Open3.capture3(cmd)
        return [stdout, stderr, status]
    end
end

class SimulatorRunner < ConsoleRunner
    def remove_file(file)
        puts "SIMULATE: removed #{file}"
    end
    
    def run(cmd)
        puts "SIMULATE: #{cmd}"
    end
end

def vputs *args
    puts *args if CmdParser.opt :verbose
end

OS = ConsoleRunner.new
# OS = SimulatorRunner.new
