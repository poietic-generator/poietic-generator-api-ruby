

module PoieticGen

  class ChatManager
    def initialize config
      @config = config
      @users = []
    end

    def update_data user, data
      data.each do | msg |
        PoieticGen::Message.post user, msg["user_dst"], msg["stamp"], msg["content"]
      end
    end

  end
end
