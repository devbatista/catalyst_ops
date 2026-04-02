class EnableVectorExtension < ActiveRecord::Migration[7.1]
  def change
    enable_extension "vector" unless extension_enabled?("vector")
  end
end
