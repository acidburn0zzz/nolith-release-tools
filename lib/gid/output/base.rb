module Gid
  module Output
    class Base
      def to_s
        raise NotImplementedError
      end
    end
  end
end
