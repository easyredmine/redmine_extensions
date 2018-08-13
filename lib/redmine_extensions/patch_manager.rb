module RedmineExtensions

  class PatchManager

    PERSISTING_PATCHES = [:force_first, :ruby, :rails, :redmine_plugins, :others]

    @@patches_locations = {}

    @@reloading_code = false
    @@reloadable_patches_applied = 0

    # is called after EasyPatchesSection load
    def self.initialize_sections
      @@registered_patches ||= ActiveSupport::OrderedHash.new
      @@registered_patches[:force_first] ||= EasyPatchesSection.new
      @@registered_patches[:ruby] ||= EasyPatchesSection.new
      @@registered_patches[:rails] ||= EasyPatchesSection.new
      @@registered_patches[:redmine_plugins] ||= EasyPatchesSection.new
      @@registered_patches[:others] ||= EasyPatchesSection.new
      @@registered_patches[:concerns] ||= EasyPatchesSection.new
      @@registered_patches[:controllers] ||= EasyPatchesSection.new
      @@registered_patches[:helpers] ||= EasyPatchesSection.new
      @@registered_patches[:models] ||= EasyPatchesSection.new
    end

    def self.patches_locations
      @@patches_locations
    end

    def self.with_reloading_code
      @@reloading_code = true
      yield
    ensure
      @@reloading_code = false
    end

    def self.reloadable_patches_applied
      @@reloadable_patches_applied
    end

    # register_patch
    # => original_klass_to_patch: 'Project', 'CustomField'
    # => patching_module: 'EasyPatch::MembersHelperPatch'
    # => options:
    # =>          :first
    # =>          :before => 'CustomField'
    # =>          :after => 'Project'
    # =>          :last
    # =>          :if => Proc.new{ Object.const_defined?(:EasyBudgetSheetQuery) }
    def self.register_patch(original_klasses_to_patch, patching_module, options={})
      return if @@reloading_code

      options ||= {}

      begin
        const = patching_module.constantize
        @@patches_locations[patching_module] = const.methods(false).map{|m| const.method(m) }.first.source_location.first
      rescue
        # [0] is register_*_patch
        from_location = caller_locations[1]
        @@patches_locations[patching_module] = from_location.absolute_path
      end

      raise ArgumentError, 'EasyPatchManager->register_patch: The \'patching_module\' have to be a string!' unless patching_module.is_a?(String)

      if original_klasses_to_patch.is_a?(String)
        original_klasses_to_patch = [original_klasses_to_patch]
      elsif original_klasses_to_patch.is_a?(Array)
        original_klasses_to_patch = original_klasses_to_patch.collect(&:to_s)
      else
        raise ArgumentError, 'EasyPatchManager->register_patch: The \'original_klass_to_patch\' have to be a string or array of strings!'
      end

      raise ArgumentError, "EasyPatchManager->register_patch: The \'patching_module\' (#{patching_module}) already exists!" if EasyPatch.all_patching_modules.include?( patching_module )

      if options[:section]
        section = options.delete(:section).to_sym
      end
      section ||= :others

      raise ArgumentError, "EasyPatchManager->register_patch: The section (#{section}) must be one of x#{@@registered_patches.keys.join(', ')}x " unless @@registered_patches.keys.include?(section)

      original_klasses_to_patch.each do |original_klass_to_patch|
        pcollection = @@registered_patches[section].move_and_get_or_insert( original_klass_to_patch, options )
        pcollection << EasyPatch.new(original_klass_to_patch, patching_module, options)
      end
    end
    private_class_method :register_patch


    def self.register_ruby_patch(original_klass_to_patch, patching_module, options={})
      register_patch(original_klass_to_patch, patching_module, {:section => :ruby}.merge(options))
    end

    def self.register_rails_patch(original_klass_to_patch, patching_module, options={})
      register_patch(original_klass_to_patch, patching_module, {:section => :rails}.merge(options))
    end

    def self.register_redmine_plugin_patch(original_klass_to_patch, patching_module, options={})
      register_patch(original_klass_to_patch, patching_module, {:section => :redmine_plugins}.merge(options))
    end

    def self.register_other_patch(original_klass_to_patch, patching_module, options={})
      register_patch(original_klass_to_patch, patching_module, {:section => :others}.merge(options))
    end

    def self.register_concern_patch(original_klass_to_patch, patching_module, options={})
      register_patch(original_klass_to_patch, patching_module, {:section => :concerns}.merge(options))
    end

    def self.register_controller_patch(original_klass_to_patch, patching_module, options={})
      register_patch(original_klass_to_patch, patching_module, {:section => :controllers}.merge(options))
    end

    def self.register_helper_patch(original_klass_to_patch, patching_module, options={})
      register_patch(original_klass_to_patch, patching_module, {:section => :helpers}.merge(options))
    end

    def self.register_model_patch(original_klass_to_patch, patching_module, options={})
      register_patch(original_klass_to_patch, patching_module, {:section => :models}.merge(options))
    end

    def self.register_patch_to_be_first(original_klass_to_patch, patching_module, options={})
      register_patch(original_klass_to_patch, patching_module, {:section => :force_first}.merge(options))
    end

    def self.register_easy_page_helper(*helper_or_helpers_klass_name)
      @registered_easy_page_helpers ||= []
      helper_or_helpers_klass_name.each do |helper_klass_name|
        @registered_easy_page_helpers << helper_klass_name if !@registered_easy_page_helpers.include?(helper_klass_name)
      end
      @registered_easy_page_helpers
    end

    def self.register_easy_page_controller(*controller_or_controllers_klass_name)
      @registered_easy_page_controllers ||= []
      controller_or_controllers_klass_name.each do |controller_klass_name|
        @registered_easy_page_controllers << controller_klass_name if !@registered_easy_page_controllers.include?(controller_klass_name)
      end
      @registered_easy_page_controllers
    end

    def self.apply_easy_page_patches
      return if @registered_easy_page_controllers.nil? || @registered_easy_page_helpers.nil?
      @registered_easy_page_controllers.each do |controller_klass_name|
        controller_klass = controller_klass_name.constantize

        @registered_easy_page_helpers.each do |helper_klass_name|
          if helper_klass_name.end_with?('Helper')
            helper_klass_symbol = helper_klass_name[0, helper_klass_name.index('Helper')]
          end

          controller_klass.class_eval "helper :#{helper_klass_symbol.underscore}" if helper_klass_symbol
          controller_klass.class_eval "include #{helper_klass_name}"
        end
      end
    end

    def self.apply_persisting_patches
      PERSISTING_PATCHES.each do |section|
        @@registered_patches[section].apply_all_patches
      end

      true
    end

    def self.apply_reloadable_patches
      (@@registered_patches.keys - PERSISTING_PATCHES).each do |section|
        reloading_log "Applying #{section} patches (#{@@registered_patches[section].count})"
        @@registered_patches[section].apply_all_patches
      end

      reloading_log("Applying page module patches")
      apply_easy_page_patches

      @@reloadable_patches_applied += 1
      true
    end

    def self.reloading_log(message)
      return if @@reloadable_patches_applied <= 1
      puts "PatchManager: #{message}"
    end

    class EasyPatchesSection
      include Enumerable

      # attr_reader :name, :order

      def initialize #( name = nil, order = nil )
        # raise ArgumentError, 'Section order has to be a integer!' unless order.is_a?(Numeric)
        # @name = name
        # @order = order
        @patches_collections = Array.new
        @last_order = 0
      end

      def each(&block)
        @patches_collections.each do |patch_collection|
          if block_given?
            block.call patch_collection
          else
            yield patch_collection
          end
        end
      end

      def apply_all_patches
        @patches_collections.each do |patch_collection|
          patch_collection.apply_all_patches
        end
      end

      def [](name)
        pcollection = @patches_collections.detect{|patch_col| patch_col.name == name }
      end

      def include_patch?(name)
        !!@patches_collections.detect{|patch_col| patch_col.name == name }
      end

      def move_and_get_or_insert( name, options )
        pcollection = @patches_collections.detect{|patch_col| patch_col.name == name }
        founded_order = find_order( options )
        if pcollection
          if founded_order
            pcollection.order = founded_order
            update_order_by(pcollection)
          end
        else
          pcollection = insert( name, founded_order )
        end
        pcollection
      end

      def find_order( options )
        if options.delete(:first)
          return 1
        elsif before = options.delete(:before)

          if before.is_a? Array
            min = nil
            before.each do |before_class_name|
              actual = nil
              before_patch = self[before_class_name]
              actual = before_patch.order if before_patch
              if actual && ( !min || actual < min )
                min = actual
              end
            end
            return min
          else
            before_patch = self[before]
            return before_patch.order + 1 if before_patch
          end

        elsif after = options.delete(:after)

          if after.is_a? Array
            max = -1
            after.each do |after_class_name|
              actual = nil
              after_patch = self[after_class_name]
              actual = after_patch.order + 1 if after_patch
              if actual && actual > max
                max = actual
              end
            end
            return max
          else
            after_patch = self[after]
            return after_patch.order + 1 if after_patch
          end

        elsif options.delete(:last)
          # do nothing
        end

        nil
      end

      private

      def push_back( collection )
        # => ambitious, if it is private method...
        # raise ArgumentError, "Section already contains a collection #{collection.name}" if @patches_collections.detect{ |coll| collection.name == coll.name }
        @patches_collections << collection
      end

      def last_order
        @last_order += 1
      end

      def insert( name, order = nil )
        final_order = order || last_order
        collection = EasyPatchesCollection.new( name, final_order )
        push_back( collection )
        update_order_by( collection ) if order
        collection
      end

      def update_order_by( collection )
        @patches_collections.select {|patch_coll| ( patch_coll.name != collection.name ) && ( patch_coll.order >= collection.order ) }.each do |col|
          col.order = col.order + 1
        end
        @patches_collections.sort!
      end

    end

    initialize_sections

    class EasyPatchesCollection

      include Comparable
      include Enumerable

      attr_reader :name, :patches
      attr_accessor :order

      def initialize(name, order = nil)
        @name = name
        @patches = []
        @order = order || 0
      end

      alias_method :original_klass_to_patch, :name

      def apply_all_patches
        @patches.each do |ep|
          ep.apply_patch
        end
      end

      def each(&block)

        @patches.each do |patch|
          if block_given?
            block.call patch
          else
            yield patch
          end
        end

      end

      def <<(ep)
        raise ArgumentError, 'patch class have to be a EasyPatch!' unless ep.is_a?(EasyPatch)
        @patches << ep
      end

      def <=> other
        self.order <=> other.order
      end

    end


    class EasyPatch

      def self.all_patching_modules
        @@all_patching_modules ||= []
      end

      def all_patching_modules
        self.class.all_patching_modules
      end

      attr_accessor :original_klass_to_patch, :patching_module, :options

      def initialize(original_klass_to_patch, patching_module, options = {})
        @original_klass_to_patch, @patching_module, @options = original_klass_to_patch, patching_module, options
        all_patching_modules << patching_module
      end

      def to_s
        "#{@original_klass_to_patch} <= #{@patching_module}"
      end

      def inspect
        to_s
      end

      def apply_patch
        if (cond = @options[:if]) && cond.respond_to?(:call)
          return unless cond.call
        end

        pm_klass = easy_constantize(patching_module)
        # pm_klass.class_eval { unloadable }

        oktp_klass = easy_constantize(original_klass_to_patch)

        if oktp_klass.include?(pm_klass)
          puts "Patch (#{oktp_klass} #{pm_klass}) is already included!"
        else
          if @options[:prepend]
            oktp_klass.prepend pm_klass
          else
            oktp_klass.include pm_klass
          end
        end
      end

      def easy_constantize(name)
        const = name.constantize
      rescue NameError
        if RedmineExtensions::PatchManager.patches_locations.has_key?(name)
          RedmineExtensions::PatchManager.with_reloading_code do
            load RedmineExtensions::PatchManager.patches_locations[patching_module]
          end

          name.constantize
        else
          raise
        end
      end

    end

  end

  module Reloader
    def self.to_prepare(*args, &block)
      if defined? ActiveSupport::Reloader
        ActiveSupport::Reloader.to_prepare(*args, &block)
      else
        ActionDispatch::Reloader.to_prepare(*args, &block)
      end
    end

    def self.to_cleanup(*args, &block)
      if defined? ActiveSupport::Reloader
        ActiveSupport::Reloader.to_complete(*args, &block)
      else
        ActionDispatch::Reloader.to_cleanup(*args, &block)
      end
    end
  end
end

ActiveSupport.on_load(:easyproject, yield: true) do
  RedmineExtensions::PatchManager.apply_persisting_patches
end

RedmineExtensions::Reloader.to_prepare do
  RedmineExtensions::PatchManager.apply_reloadable_patches
end
