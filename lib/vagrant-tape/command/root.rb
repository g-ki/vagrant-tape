module VagrantPlugins
  module Tape
    module Command

      class Root < Vagrant.plugin('2', :command)

        def self.synopsis
          'records all executed commands'
        end

        def initialize(argv, env)
          super

          @main_args, @sub_command, @sub_args = split_main_and_subcommand(argv)
          @subcommands = Vagrant::Registry.new

          @subcommands.register(:record) do
            require_relative "record"
            Record
          end

          @subcommands.register(:play) do
            require_relative "play"
            Play
          end

        end

        def execute
          if @main_args.include?("-h") || @main_args.include?("--help")
            # Print the help for all the sub-commands.
            return help
          end

          # If we reached this far then we must have a subcommand. If not,
          # then we also just print the help and exit.
          command_class = @subcommands.get(@sub_command.to_sym) if @sub_command
          # return help if !command_class || !@sub_command
          if !command_class || !@sub_command
            puts @sub_command

            command_class = @subcommands.get(:record)
          end
          @logger.debug("Invoking command class: #{command_class} #{@sub_args.inspect}")

          # Initialize and execute the command class
          command_class.new(@sub_args, @env).execute
        end

        def help
          opts = OptionParser.new do |o|
            o.banner = 'Usage: vagrant tape <command>. Default command is record.'
            o.separator ''

            # Add the available subcommands as separators in order to print them
            # out as well.
            keys = []
            @subcommands.each { |key, value| keys << key.to_s }

            keys.sort.each do |key|
              o.separator "     #{key}"
            end
          end # OptionParser

          @env.ui.info(opts.help, prefix: false)
        end
      end

    end
  end
end
