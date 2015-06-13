
module PoieticGen

  class ChatManager
    def initialize config
      @config = config
      @users = []
    end

    def update_data user, data
      data.each do | msg |
        PoieticGen::Message.post user.id, msg["user_dst"], msg["content"], user.board
      end
    end

  end
end
