module Mongoid
  # Mongoid Slug generates a URL slug or permalink based on one or more fields
  # in a Mongoid model.
  module Slug
    extend ActiveSupport::Concern

    included do
      # Internal: Gets/Sets a Mongoid::Slug::Config object.
      cattr_accessor :_slug
    end

    module ClassMethods
      # Defines a slug on one or more fields in the document.
      #
      # It takes a splat Array that includes fields and an optional last
      # element that is a Hash of options.
      #
      # fields  - Names of one or more Symbol fields used to build the slug.
      # options - The Hash options used to configure the slug (default: {}).
      #           :as        - the name of the field that stores the slug
      #                        (default: 'slug').
      #           :history   - Whether past slugs should be retained. If true,
      #                        slug searches will match both past and present
      #                        slugs (default: false).
      #           :index     - Whether an index should be defined on the field
      #                        that stores the slug. This has no effect if the
      #                        slugged document is embedded (default: false).
      #           :permanent - Whether the slug should be immutable (default:
      #                        false).
      #           :reserve   - An Array of reserved words that should not be
      #                        used as slugs (default: []).
      #           :scope     - A reference association or field to scope the
      #                        slug by. Embedded documents are, by default,
      #                        scoped by their parent. Otherwise, defaults to
      #                        nil.
      #
      # Yields a block that may be used to define a custom slug builder.
      #
      # Returns nothing.
      def slug(*args, &blk)
        self._slug = Config.new *args, &blk

        # Define a field to store slugs.
        field _slug.name, :type => Array, :default => []

        # Index the slug field.
        if _slug.indexed?
          keys = [[_slug.name, 1]]
          keys << [_slug.scope, 1] if _slug.scoped?
          index keys, :unique => true
        end

        # Alias attribute methods if slug field was renamed.
        if _slug.renamed?
          alias_method    :slug, _slug.name
          alias_attribute :slug, _slug.name
        end

        # Set up a callback to build the slug.
        set_callback _slug.event, :before do |doc|
          doc.build_slug if doc.slug_should_be_built?
        end


        # Deprecated: Define dynamic scope.
        scope "by_#{_slug.name}", lambda { |slug|
          ActiveSupport::Deprecation.warn \
            "find_by_#{_slug.name} is deprecated (use find instead)"

          where(_slug.name => slug)
        }

        # Deprecated: Define dynamic finders.
        instance_eval <<-EOF
          def self.find_by_#{_slug.name}(slug)
            by_#{_slug.name}(slug).first
          end

          def self.find_by_#{_slug.name}!(slug)
            ActiveSupport::Deprecation.warn \
              'find_by_#{_slug.name}! is deprecated (use find instead)'

            find slug
          end
        EOF
      end
    end

    # Internal: Builds or rebuilds slug.
    #
    # Returns nothing.
    def build_slug
      self.slug = [] unless _slug.has_history?
      slug.push(find_unique_slug).uniq!
    end

    # Internal: Finds a unique slug by calling the slug builder unless a slug
    # was manually specified.
    def find_unique_slug
      find_unique_slug_for begin
        if slug.present? && (new_record? || slug_changed?)
          slug
        else
          _slug.builder.call self
        end
      end
    end

    # Finds a unique entry for queried slug.
    #
    # query - A String slug.
    #
    # Returns a String slug.
    def find_unique_slug_for(query)
      new_slug = query.to_url

      # Regular expression that matches slug, slug-1,... slug-n.
      pattern = /^#{Regexp.escape(new_slug)}(?:-(\d+))?$/

      dups = Uniqueness::Scope.new(self).
        build.
        only(_slug.name).
        where(:_id.ne               => _id).
        where(_slug.name.to_sym.all => [pattern]).
        map(&:slug).
        flatten

      # Do not allow BSON::ObjectIds or reserved words as slugs.
      dups << new_slug if BSON::ObjectId.legal?(new_slug) ||
                          _slug.reserved_words.any? { |word| word == new_slug }

      unless dups.empty?
        # Sort the existing_slugs in increasing order by comparing the suffix
        # numbers: slug, slug-1, slug-2,... slug-n.
        dups.sort! do |a, b|
          (pattern.match(a)[1] || -1).to_i <=> (pattern.match(b)[1] || -1).to_i
        end
        max = dups.last.match(/-(\d+)$/).try(:[], 1).to_i

        new_slug += "-#{max + 1}"
      end

      new_slug
    end

    # Internal: Returns whether the slug should be built or rebuilt.
    def slug_should_be_built?
      new_record? || slug_changed? || slugged_attributes_changed?
    end

    # Internal: Returns whether any of the fields that are used to build the
    # slug have changed.
    def slugged_attributes_changed?
      _slug.fields.any? { |f| attribute_changed? f }
    end

    # Returns a String that Action Pack uses to construct an URL to the record.
    def to_param
      case slug
      # Build slug if missing.
      when []
        build_slug
        save
      # Wrap deprecated String slugs.
      when String
        self.slug = [slug]
        save
      end

      slug.first
    end
  end
end
