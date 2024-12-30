class CreateProspects < ActiveRecord::Migration[7.1]
  def change
    create_table :prospects do |t|
      t.string :index

      t.timestamps
    end
  end
end
