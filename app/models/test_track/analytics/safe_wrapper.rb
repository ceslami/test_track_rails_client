module TestTrack::Analytics
  class SafeWrapper
    attr_reader :underlying

    def initialize(underlying)
      @underlying = underlying
    end

    def error_handler=(handler)
      raise ArgumentError, "error_handler must be a lambda" unless handler.lambda?
      raise ArgumentError, "error_handler must accept 1 argument" unless handler.arity == 1
      @error_handler = handler
    end

    def track_assignment(visitor_id, assignment, params = {})
      safe_action { underlying.track_assignment(visitor_id, assignment, params) }
    end

    def alias(visitor_id, existing_id)
      safe_action { underlying.alias(visitor_id, existing_id) }
    end

    private

    def error_handler
      @error_handler || ->(e) do
        if Object.const_defined?(:Airbrake)
          Airbrake.notify e
        else
          Rails.logger.error e
        end
      end
    end

    def safe_action
      yield
      true
    rescue StandardError => e
      error_handler.call e
      false
    end
  end
end
