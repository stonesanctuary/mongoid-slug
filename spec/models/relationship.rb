class Relationship
  include Mongoid::Document
  embeds_many :partners
  embedded_in :person
end
