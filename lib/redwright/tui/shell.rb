# frozen_string_literal: true

module Redwright
  module Tui
    class Shell
      CLEAR_SCREEN = "\e[2J\e[H"

      def initialize(output: $stdout, title: "RedWright TUI")
        @output = output
        @title = title
        @messages = []
        @input_hint = "Type a request and press Enter."
      end

      def enter!
        render
      end

      def exit!
        @output.puts
      end

      def add_user_message(text)
        return if text.to_s.strip.empty?

        @messages << "you> #{text}"
        trim_messages!
        render
      end

      def add_runtime_message(text)
        return if text.to_s.strip.empty?

        @messages << "rw> #{text}"
        trim_messages!
        render
      end

      def render
        @output.print(CLEAR_SCREEN)
        @output.puts("=== #{@title} ===")
        @output.puts("-- Messages --")
        if @messages.empty?
          @output.puts("(no messages yet)")
        else
          @messages.each { |line| @output.puts(line) }
        end
        @output.puts("-- Input --")
        @output.puts(@input_hint)
      end

      private

      def trim_messages!
        @messages = @messages.last(30)
      end
    end
  end
end
