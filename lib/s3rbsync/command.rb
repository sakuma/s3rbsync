require 'thor'

module S3rbsync
  class Command < Thor
    include Thor::Actions

    desc 'init', "Set up S3rbsync. (ganerate configure)"
    def init
      if yes? "Do you wish to continue [yes(y) / no(n)] ?", :cyan
        say "-------- Input AWS kyes --------", :bold
        access_key  = ask("AWS ACCESS KEY:", :bold)
        secret_key  = ask("AWS SECRET ACCESS KEY:", :bold)
        say "-------- Select region --------", :bold
        print_table(print_region)
        begin
          region  = ask("\nRegin:", :bold)
        end until Region.names.include?(region)
        bucket_name = ask("Bucket name:", :bold)
        create_file "~/.aws.yml" do
          <<-"YAML"
:aws_access_key:         #{access_key}
:aws_secret_access_key:  #{secret_key}
:regin:                  #{region}
:bucket_name:            #{bucket_name}
          YAML
        end
      else
        puts "...exit"
      end
    end

    desc 'sync', "Synchronize files to S3."
    method_option :directory, :type => :string, :aliases => "-d", :default => "./"
    def sync
      conf = S3rbsync::Configure.new
      unless conf.valid?
        say "Sync failed!: configure is invalid.", :red
        exit 1
      end
      synchronizer = S3rbsync::Synchronizer.new(conf, options[:directory])
      say "Sync start...", :cyan
      synchronizer.sync!
      say "...finish.", :cyan
    end

    desc 'test', "The connection test to AWS."
    def test
      say "\nChecking config...\n", :cyan
      conf = S3rbsync::Configure.new
      print "Config file: "
      if conf.valid_yaml_file?
        say "OK\n", :green
      else
        say "NG\n", :red
        say "\n...Done\n", :cyan
        exit 1
      end

      print "Test connection: "
      if conf.connected?
        say "OK", :green
        #]...
      else
        say "NG", :red
        say "  -> Connection falid: Chack config file, or 's3rbsync init'", :yellow
      end
      say "\n...Done\n", :cyan
    end


    private

    def print_region
      list = Region.printable_list
      list.first.map!{|r| set_color(r, :cyan)}
      list.last.map!{|d| set_color(d, :magenta)}
      list
    end

  end
end
