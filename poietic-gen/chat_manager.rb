

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

    def get_users
      list_users = []
      @users.each { |user|
        list_user.push user.pseudo
      }
      return list_user.sort
    end

    def get_inbox pseudo
      user = @users[@users.find_index{|u| u.pseudo == pseudo}]
      ib = user.inbox
      user.inbox = []
      return ib
    end
  end
end
