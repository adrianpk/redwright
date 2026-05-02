module CommandQuery
  class ApplicationDispatcher
    def self.build
      dispatcher = Dispatcher.new
      ProjectSetup::CommandQueryHandlers.register(dispatcher)
      dispatcher
    end
  end
end
