module Commandorobo
    # Constants for commandorobo.
    module Constants
        # An array of every valid Discordrb permission as a symbol.
        ValidPerms = [
            :create_instant_invite, 
            :kick_members,          
            :ban_members,           
            :administrator,         
            :manage_channels,       
            :manage_server,         
            :add_reactions,         
            :view_audit_log,
            :read_messages,
            :send_messages,
            :send_tts_messages,
            :manage_messages,
            :embed_links,    
            :attach_files,         
            :read_message_history, 
            :mention_everyone,     
            :use_external_emoji,              
            :connect,              
            :speak,                
            :mute_members,         
            :deafen_members,       
            :move_members,         
            :use_voice_activity,   
            :change_nickname,      
            :manage_nicknames,     
            :manage_roles,         
            :manage_webhooks,      
            :manage_emojis         
        ].freeze
    end
end
