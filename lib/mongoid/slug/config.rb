module Mongoid
  module Slug
    # Internal: Configures a slug.
    class Config
      # The default builder.
      #
      # It concatenates the values of the slugged fields.
      BUILDER = lambda do |doc|
        doc._slug.fields.map { |f| doc.read_attribute f }.join ' '
      end

      # The default name of the field that stores the slug.
      NAME = 'slug'

      # Returns a Proc slug builder.
      attr :builder

      # Returns an Array of the String names of the fields used to build the
      # slug.
      attr :fields

      # Initializes a slug configuration.
      def initialize(*args, &blk)
        @opts    = args.extract_options!
        @builder = block_given? ? blk : BUILDER
        @fields  = args.map(&:to_s)
      end

      # Returns the Symbol event on which slug should be built.
      def event
        permanent? ? :create : :save
      end

      # Returns whether a history of changes to the slug should be retained.
      def has_history?
        !!@opts[:history]
      end

      # Returns whether an index on the slug should be defined.
      def indexed?
        !!@opts[:index]
      end

      # Returns the String name of the field that stores the slug.
      def name
        @opts[:as] ? @opts[:as].to_s : NAME
      end

      # Returns whether the slug should be immutable.
      def permanent?
        !!@opts[:permanent]
      end

      # Returns whether the slug field has a custom name.
      def renamed?
        name != NAME
      end

      # Returns an Array of words that cannot be slugged.
      def reserved_words
        Array.wrap @opts[:reserve]
      end

      # Returns the String scope of the slug or nil if slug.
      def scope
        @opts[:scope].to_s if scoped?
      end

      # Returns whether the slug is scoped.
      def scoped?
        !!@opts[:scope]
      end
    end
  end
end
