# Commandorobo
# written by ry00001 and Team ruborobo (ry00001, Erisa Arrowsmith (Seriel))
# Originally used for ruborobo (https://github.com/ry00001/ruborobo)

require 'discordrb'
require_relative './constants.rb'
require_relative './util.rb'

# A discordrb command framework
module Commandorobo
    include Constants
    include Utils

    # Class that gets returned by Command#perm_check whenever the user does not have permission.
    # @attr_reader [Array] perm The permissions returned as an array of symbols.
    class NoPermission
        attr_reader :perm
        def initialize(perm)
            @perm = perm
        end

        # Generates a "pretty" array of strings for permissions.
        # @return [Array] An array of strings representing the pretty name for permissions.
        def prettify
            @perm.map do |t| # <hackiness>
                t.to_s.split(/_/).map(&:capitalize).join(' ')
            end # </hackiness>
        end
    end

    # Class to represent an invoker (prefix, suffix).
    # @attr_reader [String] value The value of the invoker.
    # @attr_reader [Symbol] type The type of the invoker.
    class Invoker
        attr_reader :value, :type
        def initialize(val, type, **kwargs)
            if type == :regex
                val = Regexp::new(val)
            end
            if !kwargs[:sep].nil? && type == :dual
                val = val.split(kwargs[:sep])
            end
            @value = val
            @type = type
        end

        # Internal - checks to see if regexes match.
        # @param [String] text The text to check.
        # @raise [RuntimeError] The invoker wasn't a regex.
        def match(text)
            if @type != :regex
                raise "Incorrect type for function."
            end
            return @value.match(text)
        end

        # Gets the actual command and arguments from a string.
        # @param [String] text The text to extrapolate.
        def extrapolate(text)
            case @type
            when :prefix
                return text[@value.length..text.length]
            when :suffix
                return text[0..-@value.length-1]
            when :dual
                return text[@value[0].length..-@value[1].length-1]
            when :regex
                return self.match(text)
            end
        end

        # Checks to see if the invoker is correct for the text.
        # @param [String] text The text to check.
        def check(text)
            case @type
            when :prefix
                return text.start_with? @value
            when :suffix
                return text.end_with? @value
            when :dual
                return text.start_with?(@value[0]) && text.end_with?(@value[1])
            when :regex
                return !self.match(text).nil?
            end
        end
    end

    # Class that gets passed to any block defined in {Bot#cmd}. Represents arguments.
    # @attr_reader [Array] raw The unprocessed array of strings that make up the arguments.
    class Arguments
        attr_reader :raw
        def initialize(raw)
            @raw = raw
        end
        
        # Leverages a utility function to grab switch information.
        # @return [Hash] The switches.
        def switches
            Commandorobo::Utils::consume_switch(@raw.join(' '))
        end

        # Leverages a utility function to remove switches.
        # @return [String] The 'switchless' version of the arguments.
        def noswitch
            Commandorobo::Utils::remove_switch(@raw.join(' '))
        end
    end

    # Class that represents a command.
    # @attr_reader [Symbol] name The name of the command.
    # @attr_reader [Block] code The code to execute when the command fires.
    # @attr_reader [Array] permissions The permissions required to execute the command.
    # @attr_reader [String] description The description for the command.
    # @attr [Array] invokers The invokers for the command.
    class Command
        attr_reader :name, :code, :permissions, :description
        attr_accessor :invokers
        def initialize(name, code, permissions, description, invokers, bot)
            @name = name
            @code = code
            @permissions = permissions
            @description = description
            @invokers = invokers.nil? ? [name] : invokers
	        @bot = bot
        end

        # Invokes the command.
        # @param [Discordrb::Event] event The Event object to pass to the command.
        # @param [Array] args The arguments to pass to the command.
        # @return [nil]
        def invoke(event, args)
            @code.call(event, args)
        end
        
        # Checks permissions for a command.
        # @param [Discordrb::Event] event The event to use to check.
        # @return [true, Commandorobo::NoPermission]
        def perm_check(event)
	        perms = {}
            @permissions.each do |p|
                if p == :bot_owner
                    perms[p] = @bot.owners.include?(event.author.id)
                else
                    perms[p] = event.author.permission?(p)
                end
            end
            if !perms.values.all?
                noperms = []
                perms.keys.each do |p|
                    if !perms[p]
                        noperms << p
                    end
                end
                Commandorobo::NoPermission.new(noperms)
            else
                true
            end
        end
    end

    # The main bot class.
    # An extension of discordrb's.
    # @attr [Array] invokers The invokers for the bot. Can be modified, but I'd rather you use {Bot#invoke_by}.
    # @attr_reader [Hash] config The configuration for the bot.
    # @attr_reader [Array] commands The commands, in an array. This isn't a hash because I have a method for looking them up.
    # @attr_reader [Array] listeners Bound event listeners.
    # @attr_reader [Array] owners List of user IDs to consider as bot owners.
    class Bot < Discordrb::Bot
	    attr_accessor :invokers
        attr_reader :config, :commands, :listeners, :owners
        def initialize(config, token, kwargs:{})
                @config = config
                @commands = []
                @listeners = {}
                @invokers = config['invokers'].map {|i| Commandorobo::Invoker.new(i[1], i[0].to_sym)}
                @owners = @config['owner'] || kwargs[:owners]
                super(token: token)
                # begin command
                self.message do |ev|
                    meme = self.get_invoker(ev.text)
                    if meme.nil?
                        next
                    end
                    awau = meme.extrapolate(ev.text)
                    if awau.is_a?(MatchData)
                        awau = awau[1].split(/ /)
                    else
                        awau = awau.split(/ /)
                    end
                    cmd = awau.first
                    acmd = self.get_command cmd.to_sym
                    awau.shift
                    sm = awau
                    if !acmd.nil?
                        pc = acmd.perm_check(ev)
                        if pc.is_a?(Commandorobo::NoPermission)
                            self.idispatch(:command_noperms, ev, acmd, pc)
                            next
                        end
                        begin
                            a = acmd.invoke(ev, Commandorobo::Arguments.new(sm))
                            ev.respond(a)
                        rescue Exception => err
                            self.idispatch(:command_error, ev, acmd, err)
                    else
                        self.idispatch(:command_notfound, ev, acmd)
                    end
                end
            end
        end

        # Gets a command based on its name.
        # @param [Symbol] name The command to look for.
        # @return [Commandorobo::Command] The command.
        def get_command(name)
            @commands.select {|c| c.invokers.include? name}.compact[0]
        end

        # Registers a new event hook.
        # @param [Symbol] name The event hook.
        # @param [Block] block The code to run when the event fires.
        # @return [nil]
        def evt(name, &block)
            if name.is_a? String
                name = name.to_sym
            end
            if @listeners[name].nil?
                @listeners[name] = []
            end
            @listeners[name] << block
        end

        # Internal.
        # @raise [RuntimeError] No event hooks registered for the event.
        # @return [nil]
        def idispatch(name, *args)
            if name.is_a? String
                name = name.to_sym
            end
            thing = @listeners[name]
            if thing.nil?
                raise "No event hooks registered for #{name.to_s}"
            else
                thing.each do |func|
                    func.call(*args)
                end
            end
        end

        # Adds a command.
        # @param [Symbol] sym The command name.
        # @param [Array] perms The permissions required by the command. Can be any valid discordrb permission, or :bot_owner, that will restrict to owners.
        # @param [String, nil] desc The description for the command.
        # @param [Block] block The block to run when the command is invoked.
        # @return [nil]
        def cmd(sym, perms:[], desc:nil, invokers:[], &block)
            invokers << sym
            @commands << Commandorobo::Command.new(sym, block, perms, desc, invokers, self)
        end

        # Adds an invoker.
        # @param [String] value The value of the invoker.
        # @param [Symbol] type The type of the invoker.
        # @return [nil] 
        def invoke_by(value, type, **kwargs)
            @invokers << Commandorobo::Invoker.new(value, type, kwargs)
        end

        # Grabs an invoker from text.
        # @param [String] text The text to parse.
        # @return [nil]
        def get_invoker(text)
            @invokers.map {|a| a if a.check text}.reject(&:!).first # reject all false
        end
    end
end

