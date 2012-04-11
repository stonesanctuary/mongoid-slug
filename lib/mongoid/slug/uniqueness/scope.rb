module Mongoid
  module Slug
    module Uniqueness
      # Builds a scope that returns documents that may not have identical
      # slugs.
      class Scope
        attr :document

        # Initializes a scope for given document.
        def initialize(document)
          @document = document
        end

        # Builds the scope.
        #
        # Returns a Mongoid::Criteria.
        def build
          slug.scoped? ? root.where(reference => document[reference]) : root
        end

        # The class of a document or of a document from which it descends.
        def document_class
          klass = document.class
          while klass.superclass.include? Mongoid::Document
            klass = klass.superclass
          end

          klass
        end

        # The local field that references an association by which the slug is
        # scoped.
        def reference
          if metadata = document.reflect_on_association(slug.scope)
            document.class.fields.find { |k, v| v.metadata == metadata }.first
          else
            slug.scope
          end
        end

        # The root of the scope.
        def root
          siblings || document_class
        end

        # The siblings of an embedded document.
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
