class Person
  include Mongoid::Document
  include Mongoid::Slug
  field :first
  field :last
  slug :first, :last, :as => :name
  embeds_many :relationships
end
