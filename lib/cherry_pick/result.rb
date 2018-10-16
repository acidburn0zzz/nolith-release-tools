module CherryPick
  # Represents the result of a cherry pick
  class Result
    extend Forwardable

    attr_reader :merge_request
    attr_reader :conflicts

    def_delegator :merge_request, :url

    # merge_request - The merge request we attempted to pick
    # status        - Status of the pick (`:success` or `:failure`)
    # conflicts     - An Array of conflicting file names, if any
    def initialize(merge_request, status, conflicts = [])
      @merge_request = merge_request
      @status = status
      @conflicts = conflicts
    end

    def success?
      @status == :success
    end

    def failure?
      !success?
    end
  end
end
