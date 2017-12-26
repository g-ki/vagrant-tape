module VagrantPlugins
  module Tape
    class Command < Vagrant.plugin('2', :command)

      def self.synopsis
        'records all executed commands'
      end

      def execute
        require 'pty'
        require 'io/console'
        puts "Start tape"

        master, slave = PTY.open

        in_pid = fork do
          log = File.open("test.log", "w")
          $stdin.cooked!
          $stdin.each_char do |c|
            log.write c
            master.write c
          end
          log.close
        end

        pid = spawn("vagrant ssh", in:slave, out:$stdout)
        puts "Start ssh: #{pid}"

        Process.wait pid
        puts "End of the tape"
        Process.kill("HUP", in_pid)
        Process.waitall
        puts "Close"
      end
    end
  end
end
