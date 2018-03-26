# Utility module for commandorobo
# Written by ry00001

module Commandorobo
    # Utilities for commandorobo.
    module Utils
        # Removes dashes. Used internally.
        # @param [String] i String to remove dashes from.
        # @return [String] String with no dashes.
        def self.nodash(i)
            i.split('').reject {|j| j == '-'}.join('')
        end

        # Gets switches from text.
        # @param [String] str String to parse.
        # @return [Hash] Switches as a hash.
        def self.consume_switch(str)
            nextarg = nil
            parsed = false
            switches = {}
            ws = str.split(' ')
            ws.each_with_index do |k, i|
                parsed = false
                if k.start_with?('-') && k.length > 1
                    # oh heck a switch
                    if k[1] == '-'
                        # oh heck another switch
                        k = self.nodash(k)
                        switches[k.to_sym] = ws[i+1].nil? && !ws[i+1].start_with?('-') ? true : ws[i+1]
                    else
                        # no double-switch: interpret literally
                        k = self.nodash(k)
                        if k.length == 1
                            switches[k.to_sym] = ws[i+1].nil? && !ws[i+1].start_with?('-') ? true : ws[i+1]
                        else
                            k.chars.each do |l|
                                switches[l.to_sym] = true
                            end
                            switches[switches.keys.last] = ws[i+1].nil? && !ws[i+1].start_with?('-') ? true : ws[i+1]
                        end
                    end
                end
            end
            return switches
        end

        # Does the opposite of {Commandorobo::Utils::consume_switch}, it removes switches.
        # @param [String] str String to parse.
        # @return [Array] A raw array of removed switches.
        def self.remove_switch(str)
            parsed = []
            skip = false
            str.split(' ').each do |i|
                if skip
                    skip = false
                    next
                end
                if i.start_with?('-') && i.length > 1
                    skip = true
                else
                    parsed << i
                end
            end
            parsed
        end
    end
end