# Commandorobo
# written by ry00001 and Team ruborobo (ry00001, Erisa Arrowsmith (Seriel))
# Originally used for ruborobo (https://github.com/ry00001/ruborobo)

require 'discordrb'
require_relative './constants.rb'
require_relative './util.rb'

module Commandorobo
    include Constants
    include Utils

    class NoPermission
        attr_reader :perm
        def initialize(perm)
            @perm = perm
        end

        def prettify # OH GOD PLEASE HELP ME
            @perm.map do |t| # <hackiness>
                t.to_s.split(/_/).map(&:capitalize).join(' ')
            end # </hackiness>
        end
    end

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

        def match(text)
            if @type != :regex
                raise "Incorrect type for function."
            end
            return @value.match(text)
        end

        def extrapolate(text) # I WANT AN EXCUSE TO SAY EXTRAPOLATE OK
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

    class Arguments
        attr_reader :raw
        def initialize(raw)
            @raw = raw
        end
        
        def switches
            Commandorobo::Utils::consume_switch(@raw.join(' '))
        end

        def noswitch
            Commandorobo::Utils::remove_switch(@raw.join(' '))
        end
    end

    class Command
        attr_reader :name, :code, :permissions, :description, :invokers
        def initialize(name, code, permissions, description, invokers, bot)
            @name = name
            @code = code
            @permissions = permissions
            @description = description
            @invokers = invokers.nil? ? [name] : invokers
	        @bot = bot
        end

        def invoke(event, args)
            @code.call(event, args)
        end
        
        def perm_check(event)
	        perms = {}
            @permissions.each do |p|
                if p == :bot_owner
                    perms[p] = @bot.config['owner'].include?(event.author.id)
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

    class Bot < Discordrb::Bot
	    attr_accessor :invokers
        attr_reader :config, :commands, :listeners # what the hell ruby
        def initialize(config, token, **kwargs)
                @config = config
                @commands = []
                @listeners = {}
                @invokers = config['invokers'].map {|i| Commandorobo::Invoker.new(i[1], i[0].to_sym)}
                super(token: token, **kwargs)
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

        def get_command(name)
            @commands.select {|c| c.invokers.include? name}.compact[0]
        end

        def evt(name, &block)
            if name.is_a? String
                name = name.to_sym
            end
            if @listeners[name].nil?
                @listeners[name] = []
            end
            @listeners[name] << block
        end

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

        def cmd(sym, perms:[], desc:nil, invokers:[], &block)
            invokers << sym
            @commands << Commandorobo::Command.new(sym, block, perms, desc, invokers, self)
        end

        def invoke_by(thing, type, **kwargs)
            @invokers << Commandorobo::Invoker.new(thing, type, kwargs)
        end

        def get_invoker(text)
            @invokers.map {|a| a if a.check text}.reject(&:!).first # reject all false
        end
    end
end

