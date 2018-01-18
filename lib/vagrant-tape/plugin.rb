module VagrantPlugins
  module Tape
    class Plugin < Vagrant.plugin '2'

      name 'Vagrant Tape'

      description <<-EOF
      Long description of the plugin.
      EOF

      command 'tape' do
        require_relative 'command/root'
        Command::Root
      end


    end
  end
end
