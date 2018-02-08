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
          require 'thread'
          require 'pty'
          require 'io/console'

          @logger.info('Start playing')

          in_master, in_slave = PTY.open
          out_master, out_slave = PTY.open

          input_file = File.open(input, 'r')

          ssh_pid = spawn("vagrant ssh", in:in_slave, out:out_slave)
          @logger.debug("ssh #{ssh_pid}")

          semaphore = Mutex.new
          semaphore.lock
          last_write = Time.now

          in_stream = Thread.new do
            input_file.each do |cmd|
              semaphore.lock
                in_master.puts cmd
              semaphore.unlock
              sleep(1)
            end
            input_file.close()
          end

          out_stream = Thread.new do
            last_write = Time.now

            out_master.each_char do |c|
              print c
              last_write = Time.now
            end
          end

          # sync input and output
          while in_stream.alive? do
            # if nothing is written in the last ~second execute command
            if (Time.now - last_write).to_i >= 1.3
              semaphore.unlock if semaphore.owned?
              sleep(0.5)
            end
            semaphore.try_lock
            sleep(0.5)
          end

          puts
          puts 'Tape finished'

          Process.kill("HUP", ssh_pid)
          @logger.info('End of loading')
          0
        end
      end
    end
  end
end
