module VagrantPlugins
  module Tape
    class Command < Vagrant.plugin('2', :command)

      def self.synopsis
        'records all executed commands'
      end

      def execute
        require 'pty'
        require 'io/console'

        master, slave = PTY.open
        file_master, file_slave = PTY.open

        in_pid = fork do
          $stdin.raw do |io|
            io.each_char do |c|
              file_master.write c
              master.write c
            end
          end
        end

        file_pid = fork do
          File.open("ssh-session.log", "a") do |file|
            file_slave.each { |line| file.puts line }
          end
        end

        pid = spawn("vagrant ssh", in:slave, out:$stdout)
        puts "Start ssh: #{pid}"

        Process.wait pid
        puts "End of the tape"
        Process.kill("HUP", in_pid)
        Process.kill("HUP", file_pid)
        Process.waitall
        puts "Close"
      end
    end
  end
end
