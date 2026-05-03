module CommandQuery
  class ApplicationDispatcher
    def self.build
      dispatcher = Dispatcher.new
      ProjectSetup::CommandQueryHandlers.register(dispatcher)
      ProjectProtocols::CommandQueryHandlers.register(dispatcher)
      RuntimeContainers::CommandQueryHandlers.register(dispatcher)
      DocumentManagement::CommandQueryHandlers.register(dispatcher)
      BoardWorkflow::CommandQueryHandlers.register(dispatcher)
      dispatcher
    end
  end
end
