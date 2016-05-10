class CreateX2ts < ActiveRecord::Migration
  def change
    create_table :x2ts do |t|
      t.string :name
      t.string :version
      t.timestamps null: false
    end
  end
end
