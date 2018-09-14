class CasUser < User
  def self.fetch_username_from_email(email)
    logger = ASpaceLogger.new($stderr)
    username = nil
    begin
      users = User.where(email: email).all
      if users.length == 1
        username  = users[0].username
      end
    rescue Exception => bang
      logger.debug("BAD email: #{email} #{bang}")
    end
    return username
  end
end
