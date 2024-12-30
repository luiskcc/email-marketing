class AddExtraExtraFieldsToProspects < ActiveRecord::Migration[7.1]
  def change
    add_column :prospects, :phone_number, :string
  end
end
