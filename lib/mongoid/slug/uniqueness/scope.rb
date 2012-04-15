module Mongoid
  module Slug
    module Uniqueness
      # Builds a scope that returns documents that may not have identical
      # slugs.
      class Scope
        # The Mongoid::Document for which the scope is built.
        attr :document

        # Initializes a scope for the given document.
        #
        # document - A slugged Mongoid::Document.
        def initialize(document)
          @document = document
        end

        # Builds the scope.
        #
        # Returns a Mongoid::Criteria.
        def build
          slug.scoped? ? root.where(reference => document[reference]) : root
        end

        # Finds slugs in the current scope matching the given slug pattern.
        #
        # selector - A String or Regexp that describes a slug.
        #
        # Returns an Array of String slugs.
        def find_slugs(selector)
          build.
            only(slug.name).
            where(:_id.ne => document._id).
            where(slug.name.to_sym.all => [selector]).
            map(&:slug).
            flatten
        end

        # Returns the Class of the document or of another document it descends
        # from.
        def document_class
          klass = document.class
          while klass.superclass.include? Mongoid::Document
            klass = klass.superclass
          end

          klass
        end

        # The name of the field that references the association that scopes the
        # slug.
        #
        # Returns a String or nil if the slug is not scoped.
        def reference
          if slug.scoped?
            if metadata = document.reflect_on_association(slug.scope)
              field = document.class.fields.find do |k, v|
                v.metadata == metadata
              end

              field.first
            else
              slug.scope
            end
          end
        end

        # The root of the scope.
        #
        # Returns a Mongoid::Criteria or Class.
        def root
          siblings || document_class
        end

        # The siblings of an embedded document.
        #
        # Returns a Mongoid::Criteria or nil.
        def siblings
          if document.embedded?
            relation = document.reflect_on_all_associations(:embedded_in).first
            document._parent.send relation.inverse_of || document.metadata.name
          end
        end

        private

        def slug
          document._slug
        end
      end
    end
  end
end
