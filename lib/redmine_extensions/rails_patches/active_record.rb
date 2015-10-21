module RedmineExtensions
  module RailsPatches
    module ActiveRecord

      def hiearchy
        klass = self.class
        hiearchy = []
        while true
          hiearchy << klass.name
          break if klass == klass.base_class
          klass = klass.superclass
        end
        hiearchy
      end

    end
  end
end
