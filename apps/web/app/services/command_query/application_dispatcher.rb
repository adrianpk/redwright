module CommandQuery
  class ApplicationDispatcher
    def self.build
      dispatcher = Dispatcher.new
      ProjectSetup::CommandQueryHandlers.register(dispatcher)
      ProjectProtocols::CommandQueryHandlers.register(dispatcher)
      RuntimeContainers::CommandQueryHandlers.register(dispatcher)
      AgentTicketExecution::CommandQueryHandlers.register(dispatcher)
      UseCases::CommandQueryHandlers.register(dispatcher)
      DocumentManagement::CommandQueryHandlers.register(dispatcher)
      BoardWorkflow::CommandQueryHandlers.register(dispatcher)
      QuizLoops::CommandQueryHandlers.register(dispatcher)
      DumpLoops::CommandQueryHandlers.register(dispatcher)
      dispatcher
    end
  end
end
