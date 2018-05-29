module Qa
  class IssuableDeduplicator
    attr_reader :issuables

    def initialize(issuables)
      @issuables = issuables
    end

    def execute
      issuables.each_with_object({}) do |issuable, hash|
        identifier = issuable.send(:id)
        hash[identifier] = issuable unless hash[identifier]
      end.values
    end
  end
end
