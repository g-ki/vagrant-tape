module VagrantPlugins
  module Tape
    module Command
      class Record < Vagrant.plugin('2', :command)
        def execute
          options = {}
          options[:output] = './Tapefile'

          opts = OptionParser.new do |o|
            o.banner = 'Usage: vagrant tape record [options]'
            o.separator ''

            o.on('-o', '--output PATH', 'PATH to the output file. Defaults to ./Tapefile') do |o|
              options[:output] = o
            end
          end

          argv = parse_options(opts)
          return 1 unless argv

          with_target_vms(argv, reverse: true) do |machine|
            record options[:output]
          end

          0
        end # execute

        def record(output)
          require 'pty'
          require 'io/console'

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
      end
    end
  end
end
