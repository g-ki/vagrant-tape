require 'pty'
require 'io/console'

module VagrantPlugins
  module Tape
    class Recorder

      # @param env Vagrant::Environment
      # @param logger Log4r::Logger
      def initialize(env, logger)
        @env = env
        @logger = logger
      end

      def run(output)
        @logger.info('Start taping')

        master, slave = PTY.open
        output_master, output_slave = PTY.open

        input_pid = fork do
          $stdin.raw do |io|
            io.each_char do |c|
              output_master.write c
              master.write c
            end
          end
        end

        output_pid = fork do
          File.open(output, "a") do |file|
            output_slave.each { |line| file.puts line }
          end
        end

        ssh_pid = spawn("vagrant ssh", in:slave, out:$stdout)
        @logger.debug("ssh #{ssh_pid}")
        Process.wait(ssh_pid)

        @logger.info('End of taping')
        Process.kill("HUP", input_pid)
        Process.kill("HUP", output_pid)
        Process.waitall

        0
      end

      def up(input)
        @logger.info('Start loading')

        master, slave = PTY.open
        input_file = File.open(input, 'r')

        ssh_pid = spawn("vagrant ssh", in:slave, out:$stdout)
        @logger.debug("ssh #{ssh_pid}")

        input_pid = fork do
          sleep 3
          input_file.each do |cmd|
            sleep 1
            master.puts cmd
          end
        end
        Process.wait(ssh_pid)

        @logger.info('End of loading')
        Process.kill("HUP", input_pid)
        input_file.close()
        Process.waitall

        0
      end
    end
  end
end
