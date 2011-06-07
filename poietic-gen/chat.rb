

module PoieticGen
  class ChatUser
    attr_reader :pseudo, :inbox
    attr_writer :pseudo, :inbox

    def initialize pseudo
      @pseudo = pseudo
      @inbox = []
    end

    def post from, stamp, message
      @inbox.push({:from => from, :stamp => stamp, :message => message})
    end
  end
  class Chat
    def initialize config
      @config = config
      @users = []
    end

    def post pseudo, stamp, message
      @users.each { | dst |
        dst.post pseudo, stamp, message
      }
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

    def join pseudo
      STDERR.puts "Chat -join- Hello '%s'" % pseudo
      @users.push(ChatUser.new pseudo)
    end

    def leave pseudo
      STDERR.puts "Chat -leave- Bye '%s'" % pseudo
      idx = @users.find_index{|u| u.pseudo == pseudo}
      @users.delete_at idx
    end
  end
end
