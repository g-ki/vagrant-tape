module VagrantPlugins
  module Tape
    module Command
      class Play < Vagrant.plugin('2', :command)
        def execute
          options = {}
          options[:input] = './Tapefile'

          opts = OptionParser.new do |o|
            o.banner = 'Usage: vagrant tape play [options]'
            o.separator ''

            o.on('-i', '--input PATH', 'PATH to the input file. Defaults to ./Tapefile') do |o|
              options[:input] = o
            end
          end

          argv = parse_options(opts)
          return 1 unless argv

          with_target_vms(argv, reverse: true) do |machine|
            play options[:input]
          end

          0
        end # execute

        def play(input)
          require 'pty'
          require 'io/console'

          @logger.info('Start loading')

          master, slave = PTY.open
          input_file = File.open(input, 'r')

          ssh_pid = spawn("vagrant ssh", in:slave, out:$stdout)
          @logger.debug("ssh #{ssh_pid}")

          input_pid = fork do
            sleep 2
            input_file.each do |cmd|
              while slave.tell < master.tell
                puts "#{slave.tell} < #{master.tell} #{cmd}"
                sleep 1
              end
              puts "#{slave.tell} >= #{master.tell} WATI IS OVER EXECUTE: #{cmd}"
              master.puts cmd
            end
            $stdin = master
            # Process.kill("HUP", ssh_pid)
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
end
